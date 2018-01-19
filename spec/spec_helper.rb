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

require 'simplecov'
SimpleCov.start
$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'Hpe3parSdk'

def class_object_to_hash(class_obj)
  hash = {}
  class_obj.instance_variables.each {|var| hash[var.to_s.delete("@")] = class_obj.instance_variable_get(var) }
  hash
end
