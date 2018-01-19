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
  class WSAPIVersion
    include Comparable
    attr_accessor :major, :minor, :revision

    def self.parse(version)
      version_parts = version.split('.')
      validate_version(version, version_parts)

      @major = version_parts[0].to_i
      @minor = version_parts[1].to_i
      @revision = version_parts[2].to_i
      obj_version = WSAPIVersion.new(@major, @minor, @revision)
      return obj_version
    end

    def initialize(major, minor, revision)
      @major = major
      @minor = minor
      @revision = revision
    end

    def <=>(other_version)
      if major < other_version.major
        return -1
      end

      if major > other_version.major
        return 1
      end

      if minor < other_version.minor
        return -1
      end

      if minor > other_version.minor
        return 1
      end

      if revision < other_version.revision
        return -1
      end

      if revision > other_version.revision
        return 1
      end

      return 0
    end

    def to_s
      major.to_s + '.' + minor.to_s + '.' + revision.to_s
    end

    private
    def self.validate_version(version, version_parts)
      if version_parts.length != 3
        raise 'Invalid Version detected ' + version
      end
    end
  end
end