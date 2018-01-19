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

describe Hpe3parSdk::FlashCacheManager do
  before(:all) do
    @url = 'https://1.1.1.1/api/v1'
  end

  after(:all) do
    @url = nil
  end

  it 'validate get flash cache' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    flash_cache_output = { 'mode' => 1, 'sizeGiB' => 128, 'state' => 1,
                           'usedSizeGiB' => 0,
                           'links' => [{ 'href' => 'https://10.22.192.253:8080/api/v1/flashcache',
                                         'rel' => 'self' }]
                          }
    output = nil, flash_cache_output
    allow(http).to receive(:get).with('/flashcache').and_return(output)
    client = Hpe3parSdk::FlashCacheManager.new(http)
    client.instance_variable_set('@http', http)
    expect(class_object_to_hash(client.get_flash_cache)).to eq(class_object_to_hash(Hpe3parSdk::FlashCache.new(flash_cache_output)))
  end

  it 'validate delete flash cache' do
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:delete).with('/flashcache')
    client = Hpe3parSdk::FlashCacheManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.delete_flash_cache)
  end

  it 'validate create flash cache with miniumum paramtere i.e. sizeinGib' do
    size_in_gib = 64
    flash_cache_create_body = { 'flashCache' => { 'sizeGiB' => size_in_gib } }
    response = { 'date' => ['Fri, 04 Aug 2017 10:23:53 GMT'], 'server' =>
        ['hp3par-wsapi'], 'cache-control' => ['no-cache'],
                 'pragma' => ['no-cache'],
                 'content-type' => ['application/json'],
                 'location' => ['/api/v1/flashcache/'],
                 'connection' => ['close'] }
    body = { 'links' => [{ 'href' => 'https://10.22.192.253:8080/api/v1/flashcache',
                           'rel' => 'flashcacheCreated' }] }
    flash_cache_create_response_body = response, body
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).with('/', body: flash_cache_create_body)
      .and_return(flash_cache_create_response_body)
    client = Hpe3parSdk::FlashCacheManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.create_flash_cache(size_in_gib, nil)).to eq(body)
  end

  it 'validate create flash cache with all parameters' do
    size_in_gib = 64
    mode = 1
    flash_cache_create_body = { 'flashCache' => { 'sizeGiB' => size_in_gib,
                                                  'mode' => mode } }
    response = { 'date' => ['Fri, 04 Aug 2017 10:23:53 GMT'], 'server' =>
        ['hp3par-wsapi'], 'cache-control' => ['no-cache'],
                 'pragma' => ['no-cache'],
                 'content-type' => ['application/json'],
                 'location' => ['/api/v1/flashcache/'],
                 'connection' => ['close'] }
    body = { 'links' => [{ 'href' => 'https://10.22.192.253:8080/api/v1/flashcache',
                           'rel' => 'flashcacheCreated' }] }
    flash_cache_create_response_body = response, body
    http = Hpe3parSdk::HTTPJSONRestClient.new(@url, false, false, false, nil)
    allow(http).to receive(:post).with('/', body: flash_cache_create_body)
      .and_return(flash_cache_create_response_body)
    client = Hpe3parSdk::FlashCacheManager.new(http)
    client.instance_variable_set('@http', http)
    expect(client.create_flash_cache(size_in_gib, mode)).to eq(body)
  end
end
