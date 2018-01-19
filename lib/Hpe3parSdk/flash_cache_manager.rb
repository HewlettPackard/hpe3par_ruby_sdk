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

require_relative 'util'
require_relative 'models'

module Hpe3parSdk
  # Adaptive Flash Cache Rest API methods
  class FlashCacheManager
    def initialize(http)
      @http = http
      @flash_cache_uri = '/flashcache'
    end

    def create_flash_cache(size_in_gib, mode)
      flash_cache = { 'sizeGiB' => size_in_gib }

      unless mode.nil?
        mode = { 'mode' => mode }
        flash_cache = Util.merge_hash(flash_cache, mode)
      end

      info = { 'flashCache' => flash_cache }
      _response, body = @http.post('/', body: info)
      body
    end

    def get_flash_cache
      _response, body = @http.get(@flash_cache_uri)
      FlashCache.new(body)
    end

    def flash_cache_exists?
      begin
        get_flash_cache
        return true
      rescue Hpe3parSdk::HTTPNotFound => ex
        return false  
      end
    end

    def delete_flash_cache
      _response, _body = @http.delete(@flash_cache_uri)
    end
  end
end
