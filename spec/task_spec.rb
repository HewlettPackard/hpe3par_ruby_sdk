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

require 'rspec'
require 'json'
require 'spec_helper'

describe Hpe3parSdk::TaskManager do
  before(:all) do
    @url = 'https://1.1.1.1/api/v1'
  end

  after(:all) do
    @url = nil
  end
  it 'validate get all tasks' do
    file = File.read('spec/json/tasks.json')
    all_tasks = JSON.parse(file)
    return_output = nil, all_tasks
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:get).with('/tasks').and_return(return_output)
    allow_any_instance_of(Hpe3parSdk::Client).to receive(:get_ws_api_version) { @api_hash }
    task = Hpe3parSdk::TaskManager.new(@url)
    task.instance_variable_set('@http', http)
    expect(class_object_to_hash(task.get_all_tasks)).to eq(class_object_to_hash(all_tasks['members']))
  end


  it 'validate get task by id' do
    task_id = 1
    file = File.read('spec/json/tasks.json')
    all_tasks = JSON.parse(file)
    return_output = nil, all_tasks['members'][0]
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:get).with("/tasks/#{task_id}").and_return(return_output)
    allow_any_instance_of(Hpe3parSdk::Client).to receive(:get_ws_api_version) { @api_hash }
    task = Hpe3parSdk::TaskManager.new(@url)
    task.instance_variable_set('@http', http)
    expect(task.get_task(task_id).name).to eq(Hpe3parSdk::Task.new(all_tasks['members'][0]).name)
    expect(task.get_task(task_id).type).to eq(Hpe3parSdk::Task.new(all_tasks['members'][0]).type)
  end

  it 'validate get task by id which is of non integer datatype' do
    task_id = 'non-integer-task-id'
    file = File.read('spec/json/tasks.json')
    all_tasks = JSON.parse(file)
    return_output = nil, all_tasks['members'][0]
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:get).with("/tasks/#{task_id}").and_return(return_output)
    allow_any_instance_of(Hpe3parSdk::Client).to receive(:get_ws_api_version) { @api_hash }
    task = Hpe3parSdk::TaskManager.new(@url)
    task.instance_variable_set('@http', http)
    expect { task.get_task(task_id) }.to raise_error("Task id '#{task_id}' is not of type integer")
  end
end
