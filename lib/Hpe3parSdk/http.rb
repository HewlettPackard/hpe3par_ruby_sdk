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

require 'httparty'
require 'json'
require 'logger'
require_relative 'exceptions'
require_relative 'multi_log'
require_relative 'util'

module Hpe3parSdk
  class HTTPJSONRestClient
    USER_AGENT = 'ruby-3parclient'.freeze
    SESSION_COOKIE_NAME = 'X-Hp3Par-Wsapi-Sessionkey'.freeze
    CONTENT_TYPE = 'application/json'.freeze

    attr_accessor :http_log_debug, :api_url, :session_key, :suppress_ssl_warnings, :timeout, :secure,
                  :logger, :log_level

    def initialize(api_url, secure = false, http_log_debug = false,
                   suppress_ssl_warnings = false, timeout = nil)
      @api_url = api_url
      @secure = secure
      @http_log_debug = http_log_debug
      @suppress_ssl_warnings = suppress_ssl_warnings
      @timeout = timeout
      @session_key = nil
      HTTParty::Logger.add_formatter('custom', CustomHTTPFormatter)
      @httparty_log_level = :info
      @httparty_log_format = :custom
      set_debug_flag
    end

    # This turns on/off http request/response debugging output to console
    def set_debug_flag
      if @http_log_debug
        @httparty_log_level = :debug
        @httparty_log_format = :curl
      end
    end

    def authenticate(user, password, _optional = nil)
      begin
        @session_key = nil

        info = {:user => user, :password => password}

        auth_url = '/credentials'
        headers, body = post(auth_url, body: info)
        @session_key = body['key']
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
      end
    end

    def set_url(api_url)
      # should be http://<Server:Port>/api/v1
      @api_url = api_url.chomp('/')
    end

    def get(url, **kwargs)
      headers, payload = get_headers_and_payload(kwargs)
      response = HTTParty.get(api_url + url,
                              headers: headers,
                              verify: secure, logger: Hpe3parSdk.logger,
                              log_level: @httparty_log_level,
                              log_format: @httparty_log_format)
      process_response(response)
    end

    def post(url, **kwargs)
      headers, payload = get_headers_and_payload(kwargs)
      response = HTTParty.post(api_url + url,
                               headers: headers,
                               body: payload,
                               verify: secure, logger: Hpe3parSdk.logger,
                               log_level: @httparty_log_level,
                               log_format: @httparty_log_format)
      process_response(response)
    end

    def put(url, **kwargs)
      headers, payload = get_headers_and_payload(kwargs)
      response = HTTParty.put(api_url + url,
                              headers: headers,
                              body: payload,
                              verify: secure, logger: Hpe3parSdk.logger,
                              log_level: @httparty_log_level,
                              log_format: @httparty_log_format)
      process_response(response)
    end

    def delete(url, **kwargs)
      headers, payload = get_headers_and_payload(kwargs)
      response = HTTParty.delete(api_url + url,
                                 headers: headers,
                                 verify: secure, logger: Hpe3parSdk.logger,
                                 log_level: @httparty_log_level,
                                 log_format: @httparty_log_format)
      process_response(response)
    end

    def process_response(response)
      headers = response.headers
      body = response.parsed_response

      if response.code != 200
        if !body.nil? && body.key?('code') && body.key?('desc')
          exception = Hpe3parSdk.exception_from_response(response, body)
          raise exception
        end
      end
      [headers, body]
    end

    def log_exception(exception, caller_location)
      formatted_stack_trace = exception.backtrace
                                  .map { |line| "\t\tfrom #{line}" }
                                  .join($/)
      err_msg = "(#{caller_location}) #{exception}#{$/}  #{formatted_stack_trace}"
      Hpe3parSdk.logger.error(err_msg)
    end

    def unauthenticate
      # delete the session on the 3Par
      unless @session_key.nil?
        begin
          delete('/credentials/%s' % session_key)
          @session_key = nil
        rescue => ex
          Util.log_exception(ex, caller_locations(1, 1)[0].label)
        end
      end
    end

    def get_headers_and_payload(**kwargs)
      if session_key
        kwargs['headers'] = kwargs.fetch('headers', {})
        kwargs['headers'][SESSION_COOKIE_NAME] = session_key
      end

      kwargs['headers'] = kwargs.fetch('headers', {})
      kwargs['headers']['User-Agent'] = USER_AGENT
      kwargs['headers']['Accept'] = CONTENT_TYPE
      if kwargs.key?(:body)
        kwargs['headers']['Content-Type'] = CONTENT_TYPE
        kwargs[:body] = kwargs[:body].to_json
        payload = kwargs[:body]
      else
        payload = nil
      end
      [kwargs['headers'], payload]
    end
  end
end

