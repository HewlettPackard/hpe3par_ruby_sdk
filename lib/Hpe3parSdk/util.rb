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

module Hpe3parSdk
  class Util
    def self.merge_hash(hash1, hash2)
      raise TypeError, 'hash1 is not a hash' unless hash1.class == Hash
      raise TypeError, 'hash2 is not a hash' unless hash2.class == Hash

      hash3 = hash2.merge(hash1)
      hash3
    end

    def self.log_exception(exception, caller_location)
      formatted_stack_trace = exception.backtrace
                                  .map { |line| "\t\tfrom #{line}" }
                                  .join($/)
      err_msg = "(#{caller_location}) #{exception}#{$/}  #{formatted_stack_trace}"
      Hpe3parSdk.logger.error(err_msg)
    end
  end
end
