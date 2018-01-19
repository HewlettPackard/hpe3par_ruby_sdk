# (c) Copyright 2016-2017 Hewlett Packard Enterprise Development LP
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.

require_relative 'exceptions'
require_relative 'models'

module Hpe3parSdk
  # Task Manager Rest API methods
  class TaskManager
    def initialize(http)
      @http = http
    end

    def get_all_tasks
      tasks = Array[]
      response = @http.get('/tasks')
      response[1]['members'].each do |member|
        tasks.push(Task.new(member))
      end
      tasks
    end

    def get_task(task_id)
      if task_id.is_a? Integer
        response = @http.get("/tasks/#{task_id}")
        Task.new(response[1])
      else
        raise Hpe3parSdk::HTTPBadRequest.new(
            nil, "Task id '#{task_id}' is not of type integer"
        )
      end
    end

    def cancel_task(task_id)
      if task_id.is_a? Integer
        _body = Hash.new
        _body['action'] = Hpe3parSdk::TaskAction::CANCEL_TASK
        @http.put("/tasks/#{task_id}", body: _body)
      else
        raise HPE3PARException.new(
            nil, "Task id #{task_id} is not of type integer"
        )
      end
    end

    def wait_for_task_to_end(task_id, poll_rate_secs)
      _wait_for_task_to_end_loop(task_id, poll_rate_secs)
    end

    def _wait_for_task_to_end_loop(task_id, poll_rate_secs)
      task = get_task(task_id)

      while task != nil do #loop begin
        state = task.status
        if state == Hpe3parSdk::TaskStatus::DONE
          break
        end

        if state == Hpe3parSdk::TaskStatus::CANCELLED
          Hpe3parSdk.logger.info("Task #{task.task_id} was CANCELLED!!!")
          break
        end

        if state == Hpe3parSdk::TaskStatus::FAILED
          msg = "Task '#{task.task_id}' has FAILED!!!"
          Hpe3parSdk.logger.info(msg)
          raise Hpe3parSdk::HPE3PARException.new(message: msg)
        end

        if state == Hpe3parSdk::TaskStatus::ACTIVE
          sleep(poll_rate_secs)
          task = get_task(task.task_id);
          Hpe3parSdk.logger
              .info("Polling task #{task.task_id} current status: #{Hpe3parSdk::TaskStatus.get_string(task.status)}")
        end

      end #loop end

      #Return the Task Result
      if task != nil && task.status != nil && task.status == 'DONE'
        return true

      else
        return false
      end

    end

  end
end
