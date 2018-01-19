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

describe Hpe3parSdk::QOSManager do
  before(:all) do
    @url = 'https://1.1.1.1/api/v1'
    @vvset_name = 'test_Set'
    @qos_rule = {
      'priority' => 2,
      'bwMinGoalKB' => 1024,
      'bwMaxLimitKB' => 1024,
      'ioMinGoal' => 10_000,
      'ioMaxLimit' => 2_000_000,
      'enable' => true,
      'bwMinGoalOP' => 1,
      'bwMaxLimitOP' => 1,
      'ioMinGoalOP' => 1,
      'ioMaxLimitOP' => 1,
      'latencyGoal' => 5000,
      'defaultLatency' => false
    }
    @vv_set_type = 1
  end

  after(:all) do
    @url = nil
  end

  it 'should get all qos' do
    file = File.read('spec/json/all_qos_rules.json')
    response = JSON.parse(file)
    body = nil
    create_qos_rule_return_body = body, response
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:get).with('/qos').and_return(create_qos_rule_return_body)
    qos_obj = Hpe3parSdk::QOSManager.new(http)
    qos_obj.instance_variable_set('@http', http)
    expect(class_object_to_hash(qos_obj.query_qos_rules)).to eq(class_object_to_hash(response['members']))
  end
  it 'should return QOS rules for given vvset' do
    url = "/qos/#{@vv_set_type}:#{@vvset_name}"
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    file = File.read('spec/json/qos.json')
    response = JSON.parse(file)
    body = nil
    create_qos_rule_return_body = body,response
    allow(http).to receive(:get).with(url).and_return(create_qos_rule_return_body)
    qos_obj = Hpe3parSdk::QOSManager.new(http)
    qos_obj.instance_variable_set('@http', http)
    expect(qos_obj.query_qos_rule(@vvset_name, @vv_set_type).enabled).to eq(create_qos_rule_return_body[1]['enabled'])
  end

  it 'should create QOS rule wth valid inputs' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    response = [nil, nil]
    allow(http).to receive(:post).and_return(response)
    qos_obj = Hpe3parSdk::QOSManager.new(http)
    qos_obj.instance_variable_set('@http', http)
    expect(qos_obj.create_qos_rules(@vvset_name, @qos_rule, @vv_set_type)).to eq(nil)
  end

  it 'should delete QOS rule for vvset with valid inputs' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    response = [nil, nil]
    allow(http).to receive(:delete).and_return(response)
    qos_obj = Hpe3parSdk::QOSManager.new(http)
    qos_obj.instance_variable_set('@http', http)
    expect(qos_obj.delete_qos_rules(@vv_set_type, @vvset_name)).to eq(nil)
  end
  it 'should modify QOS rule for the given vvset' do
    new_qos_rules = {
      'priority' => 1
    }
    file = File.read('spec/json/qos.json')
    response = JSON.parse(file)
    body = nil
    create_qos_rule_return_body = response, body
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:put).and_return(create_qos_rule_return_body)
    qos_obj = Hpe3parSdk::QOSManager.new(http)
    qos_obj.instance_variable_set('@http', http)
    expect(qos_obj.modify_qos_rules(@vvset_name, new_qos_rules, @vv_set_type)).to eq(create_qos_rule_return_body)
  end
end
