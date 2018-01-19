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
  #defined at the Module level. Can be accessed by all classes in the module
  class << self
    attr_accessor :logger
  end

  @logger = nil


  class MultiLog
    attr_reader :level

    def initialize(args={})
      @level = args[:level] || Logger::Severity::DEBUG
      @loggers = []

      Array(args[:loggers]).each { |logger| add_logger(logger) }
    end

    def add_logger(logger)
      logger.level = level
      logger.progname = 'ruby-3parclient'
      @loggers << logger
    end

    def level=(level)
      @level = level
      @loggers.each { |logger| logger.level = level }
    end

    def close
      @loggers.map(&:close)
    end

    def add(level, *args)
      @loggers.each { |logger| logger.add(level, args) }
    end

    Logger::Severity.constants.each do |level|
      define_method(level.downcase) do |*args|
        @loggers.each { |logger| logger.send(level.downcase, args) }
      end

      define_method("#{ level.downcase }?".to_sym) do
        @level <= Logger::Severity.const_get(level)
      end
    end
  end

  class CustomFormatter < Logger::Formatter #:nodoc:
    def call(severity, datetime, progname, msg)
      # msg2str is the internal helper that handles different msgs correctly
      date_format = datetime.strftime('%Y-%m-%d %H:%M:%S%z')
      "[#{date_format} ##{Process.pid}] [#{progname}] #{severity} -- : "+ msg.join($/) + "#{$/}"
    end
  end

  class CustomHTTPFormatter #:nodoc:
    attr_accessor :level, :logger, :current_time

    def initialize(logger, level)
      @logger = logger
      @level  = level.to_sym
    end

    def format(request, response)
      http_method    = request.http_method.name.split("::").last.upcase
      path           = request.path.to_s
      content_length = response.respond_to?(:headers) ? response.headers['Content-Length'] : response['Content-Length']
      @logger.send @level, "[#{response.code} #{http_method} #{path} #{content_length || '-'} ]"
    end
  end


end