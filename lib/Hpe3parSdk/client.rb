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

require_relative 'http'
require_relative 'ssh'
require_relative 'util'
require_relative 'volume_manager'
require_relative 'cpg_manager'
require_relative 'volume_set_manager'
require_relative 'qos_manager'
require_relative 'vlun_manager'
require_relative 'host_manager'
require_relative 'host_set_manager'
require_relative 'flash_cache_manager'
require_relative 'port_manager'
require_relative 'task_manager'
require_relative 'wsapi_version'

module Hpe3parSdk
  class Client
    def initialize(api_url,debug:false, secure: false, timeout: nil, suppress_ssl_warnings: false, app_type: 'ruby-3parclient', log_file_path: nil)
      unless api_url.is_a?(String)
        raise Hpe3parSdk::HPE3PARException.new(nil,
                                                  "'api_url' parameter is mandatory and should be of type String")
      end

      @api_url = api_url
      @debug = debug
      @secure = secure
      @timeout = timeout
      @suppress_ssl_warnings = suppress_ssl_warnings
      @log_level = Logger::INFO
      @log_file_path = log_file_path
      init_log
      @http = HTTPJSONRestClient.new(
          @api_url, @secure, @debug,
          @suppress_ssl_warnings, @timeout = nil
      )
      check_WSAPI_version
      @vlun_query_supported = false
      @cpg = CPGManager.new(@http)
      @qos = QOSManager.new(@http)
      @flash_cache = FlashCacheManager.new(@http)
      @port = PortManager.new(@http)
      @task = TaskManager.new(@http)
      @host_and_vv_set_filter_supported = false
      @ssh = nil
      @vlun = VlunManager.new(@http, @vlun_query_supported)
      @host = HostManager.new(@http, @vlun_query_supported)
      @volume_set = VolumeSetManager.new(@http, @host_and_vv_set_filter_supported)
      @host_set = HostSetManager.new(@http, @host_and_vv_set_filter_supported)
      @app_type = app_type
    end

    
    private def init_log
      unless @log_file_path.nil?
        client_logger = Logger.new(@log_file_path, 'daily', formatter: CustomFormatter.new)
      else
        client_logger = Logger.new(STDOUT)
      end
      if @debug
        @log_level = Logger::DEBUG
      end
      Hpe3parSdk.logger = MultiLog.new(:level => @log_level, :loggers => client_logger)
    end

    
    private def check_WSAPI_version
      begin
        @api_version = get_ws_api_version
      rescue HPE3PARException => ex
        ex_message = ex.message
        if ex_message && ex_message.include?('SSL Certificate Verification Failed')
          raise Hpe3parSdk::SSLCertFailed
        else
          msg = "Error: #{ex_message} - Error communicating with 3PAR WSAPI. '
          'Check proxy settings. If error persists, either the '
          '3PAR WSAPI is not running OR the version of the WSAPI is '
          'not supported."
          raise Hpe3parSdk::HPE3PARException(message: msg)
        end
      end

      compare_version(@api_version)

    end

    private def set_ssh_options(username, password, port=22, conn_timeout=nil)
      @ssh=Hpe3parSdk::SSH.new(@api_url.split("//")[1].split(":")[0], username, password)
    end

    private def compare_version(api_version)
      @min_version = WSAPIVersion
                         .parse(WSAPIVersionSupport::WSAPI_MIN_SUPPORTED_VERSION)
      @min_version_with_compression = WSAPIVersion
                                          .parse(WSAPIVersionSupport::WSAPI_MIN_VERSION_COMPRESSION_SUPPORT)

      @current_version = WSAPIVersion.new(api_version['major'], api_version['minor'],
                                          api_version['revision'])
      if @current_version < @min_version
        err_msg = "Unsupported 3PAR WS API version #{@current_version}, min supported version is, #{WSAPIVersionSupport::WSAPI_MIN_SUPPORTED_VERSION}"
        raise Hpe3parSdk::UnsupportedVersion.new(nil, err_msg)
      end

      # Check for VLUN query support.
      min_vlun_query_support_version = WSAPIVersion
                                           .parse(WSAPIVersionSupport::WSAPI_MIN_VERSION_VLUN_QUERY_SUPPORT)
      if @current_version >= min_vlun_query_support_version
        @vlun_query_supported = true
      end

      # Check for Host and VV Set query support
      if @current_version >= @min_version_with_compression
        @host_and_vv_set_filter_supported = true
      end

    end

    # Get the 3PAR WS API version.
    #
    # ==== Returns
    #
    # WSAPI version hash
    def get_ws_api_version
      # remove everything down to host:port
      host_url = @api_url.split('/api')
      @http.set_url(host_url[0])
      begin
        # get the api version
        response = @http.get('/api')
        response[1]
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    ensure
      # reset the url
      @http.set_url(@api_url)
    end

    # Gets the WSAPI Configuration.
    #
    # ==== Returns
    #
    # WSAPI configuration hash
    def get_ws_api_configuration_info
      begin
        response = @http.get('/wsapiconfiguration')
        response[1]
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Creates a new FlashCache
    #
    # ==== Attributes
    #
    # * size_in_gib - Specifies the node pair size of the Flash Cache on the system
    #      type size_in_gib: Integer
    # * mode - Values supported Simulator: 1, Real: 2 (default)
    #      type mode: Integer
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #       - NO_SPACE - Not enough space is available for the operation.
    # * Hpe3parSdk::HTTPBadRequest
    #       - INV_INPUT_EXCEEDS_RANGE - A JSON input object contains a name-value pair with a numeric value that exceeds the expected range. Flash Cache exceeds the expected range. The HTTP ref member contains the name.
    # * Hpe3parSdk::HTTPConflict
    #       - EXISTENT_FLASH_CACHE - The Flash Cache already exists.
    # * Hpe3parSdk::HTTPForbidden
    #       - FLASH_CACHE_NOT_SUPPORTED - Flash Cache is not supported.
    # * Hpe3parSdk::HTTPBadRequest
    #       - INV_FLASH_CACHE_SIZE - Invalid Flash Cache size. The size must be a multiple of 16 G.
    def create_flash_cache(size_in_gib, mode = nil)
      begin
        @flash_cache.create_flash_cache(size_in_gib, mode)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
      
    end

    # Get Flash Cache information
    #
    # ==== Returns
    #
    # FlashCache - Details of the specified flash cache
    def get_flash_cache
      begin
        @flash_cache.get_flash_cache
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Deletes an existing Flash Cache
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPForbidden
    #       - FLASH_CACHE_IS_BEING_REMOVED - Unable to delete the Flash Cache, the Flash Cache is being removed.
    # * Hpe3parSdk::HTTPForbidden
    #       - FLASH_CACHE_NOT_SUPPORTED - Flash Cache is not supported on this system.
    # * Hpe3parSdk::HTTPNotFound
    #       - NON_EXISTENT_FLASH_CACHE - The Flash Cache does not exist.
    def delete_flash_cache
      begin
        @flash_cache.delete_flash_cache
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets the Storage System Information
    #
    # ==== Returns
    #
    # Hash of Storage System Info
    def get_storage_system_info
      begin
        response = @http.get('/system')
        response[1]
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets the overall system capacity for the 3PAR server.
    #
    # ==== Returns
    #
    # Hash of system capacity information
    #
    #
    #     capacity = {
    #       "allCapacity"=> {                       # Overall system capacity
    #                                               # includes FC, NL, SSD
    #                                               # device types
    #         "totalMiB"=>20054016,                 # Total system capacity
    #                                               # in MiB
    #         "allocated"=>{                        # Allocated space info
    #           "totalAllocatedMiB"=>12535808,      # Total allocated
    #                                               # capacity
    #           "volumes"=> {                       # Volume capacity info
    #             "totalVolumesMiB"=>10919936,      # Total capacity
    #                                               # allocated to volumes
    #             "nonCPGsMiB"=> 0,                 # Total non-CPG capacity
    #             "nonCPGUserMiB"=> 0,              # The capacity allocated
    #                                               # to non-CPG user space
    #             "nonCPGSnapshotMiB"=>0,           # The capacity allocated
    #                                               # to non-CPG snapshot
    #                                               # volumes
    #             "nonCPGAdminMiB"=> 0,             # The capacity allocated
    #                                               # to non-CPG
    #                                               # administrative volumes
    #             "CPGsMiB"=>10919936,              # Total capacity
    #                                               # allocated to CPGs
    #             "CPGUserMiB"=>7205538,            # User CPG space
    #             "CPGUserUsedMiB"=>7092550,        # The CPG allocated to
    #                                               # user space that is
    #                                               # in use
    #             "CPGUserUnusedMiB"=>112988,       # The CPG allocated to
    #                                               # user space that is not
    #                                               # in use
    #             "CPGSnapshotMiB"=>2411870,        # Snapshot CPG space
    #             "CPGSnapshotUsedMiB"=>210256,     # CPG allocated to
    #                                               # snapshot that is in use
    #             "CPGSnapshotUnusedMiB"=>2201614,  # CPG allocated to
    #                                               # snapshot space that is
    #                                               # not in use
    #             "CPGAdminMiB"=>1302528,           # Administrative volume
    #                                               # CPG space
    #             "CPGAdminUsedMiB"=> 115200,       # The CPG allocated to
    #                                               # administrative space
    #                                               # that is in use
    #             "CPGAdminUnusedMiB"=>1187328,     # The CPG allocated to
    #                                               # administrative space
    #                                               # that is not in use
    #             "unmappedMiB"=>0                  # Allocated volume space
    #                                               # that is unmapped
    #           },
    #           "system"=> {                        # System capacity info
    #              "totalSystemMiB"=> 1615872,      # System space capacity
    #              "internalMiB"=>780288,           # The system capacity
    #                                               # allocated to internal
    #                                               # resources
    #              "spareMiB"=> 835584,             # Total spare capacity
    #              "spareUsedMiB"=> 0,              # The system capacity
    #                                               # allocated to spare resources
    #                                               # in use
    #              "spareUnusedMiB"=> 835584        # The system capacity
    #                                               # allocated to spare resources
    #                                               # that are unused
    #             }
    #         },
    #           "freeMiB"=> 7518208,                # Free capacity
    #           "freeInitializedMiB"=> 7518208,     # Free initialized capacity
    #           "freeUninitializedMiB"=> 0,         # Free uninitialized capacity
    #           "unavailableCapacityMiB"=> 0,       # Unavailable capacity in MiB
    #           "failedCapacityMiB"=> 0             # Failed capacity in MiB
    #       },
    #       "FCCapacity"=>  {                       # System capacity from FC devices only
    #           ...                                 # Same structure as above
    #       },
    #       "NLCapacity"=>  {                       # System capacity from NL devices only
    #           ...                                 # Same structure as above
    #       },
    #       "SSDCapacity"=>  {                      # System capacity from SSD devices only
    #           ...                                 # Same structure as above
    #       }
    #     }
    def get_overall_system_capacity   
      begin
        response = @http.get('/capacity')
        response[1]
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # This authenticates against the 3PAR WSAPI server and creates a session.

    # ==== Attributes
    #
    # * username - The username
    #      type username: String
    # * password - The Password
    #      type password: String
    def login(username, password, optional = nil)
      set_ssh_options(username, password, port=22, conn_timeout=nil)
      @volume = VolumeManager.new(@http, @ssh, @app_type)
      @http.authenticate(username, password, optional)
    end

    # Get the list of all 3PAR Tasks
    #
    # ==== Returns
    #
    # Array of Task
    def get_all_tasks
      begin
        @task.get_all_tasks
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end 
    end

    # Get the status of a 3PAR Task
    #
    # ==== Attributes
    #
    # * task_id - the task id
    #      type task_id: Integer
    #
    # ==== Returns
    #
    # Task
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_BELOW_RANGE - Bad Request Task ID must be a positive value.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_EXCEEDS_RANGE - Bad Request Task ID is too large.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_TASK - Task with the specified Task ID does not exist.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_WRONG_TYPE - Task ID is not an integer.
    def get_task(task_id)
      begin
        @task.get_task(task_id)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end 
    end
    
  
    def vlun_exists?(volname,lunid,host=nil,port=nil)
      begin
         @vlun.vlun_exists?(volname,lunid,host,port)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Creates a new VLUN.
    #
    # When creating a VLUN, the volumeName is required. The lun member is
    # not required if auto is set to True.
    # Either hostname or portPos (or both in the case of matched sets) is
    # also required.  The noVcn and overrideLowerPriority members are
    # optional.
    # * volume_name: Name of the volume to be exported
    #     type volume_name: String
    # * lun: LUN id
    #     type lun: Integer
    # * host_name:  Name of the host which the volume is to be exported.
    #     type host_name: String
    # * port_pos: System port of VLUN exported to. It includes node number, slot number, and card port number
    #     type port_pos: Hash
    #         port_pos = {'node'=> 1,   # System node (0-7)
    #                    'slot'=> 2,    # PCI bus slot in the node (0-5)
    #                    'port'=> 1}    # Port number on the FC card (0-4)
    # * no_vcn: A VLUN change notification (VCN) not be issued after export (-novcn).
    #     type no_vcn: Boolean
    # * override_lower_priority: Existing lower priority VLUNs will be overridden (-ovrd). Use only if hostname member exists.
    #     type override_lower_priority: Boolean
    #
    # ==== Returns
    #
    # VLUN id
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        -  INV_INPUT_ MISSING_REQUIRED - Missing volume or hostname or lunid.
    # * Hpe3parSdk::HTTPNotFound
    #        -  NON_EXISTENT_VOL MISSING_REQUIRED - Specified volume does not exist.
    # * Hpe3parSdk::HTTPNotFound
    #        -  NON_EXISTENT_HOST - Specified hostname not found.
    # * Hpe3parSdk::HTTPNotFound
    #        -  NON_EXISTENT_PORT - Specified port does not exist.
    def create_vlun(volume_name, lun = nil, host_name = nil, port_pos = nil, no_vcn = false, override_lower_priority = false, auto = false)
      begin
        @vlun.create_vlun(volume_name, host_name, lun, port_pos, no_vcn, override_lower_priority, auto)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets VLUNs.
    #
    # ==== Returns
    #
    # Array of VLUN objects
    def get_vluns
      begin
        @vlun.get_vluns
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets information about a VLUN.
    #
    # ==== Attributes
    #
    # * volume_name: The volume name of the VLUN to find
    #      type volume_name: String
    #
    # ==== Returns
    #
    # VLUN object
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPNotFound
    #        -  NON_EXISTENT_VLUN - VLUN doesn't exist
    def get_vlun(volume_name)
      begin
        @vlun.get_vlun(volume_name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Deletes a VLUN.
    #
    # ==== Attributes
    #
    # * volume_name: Volume name of the VLUN
    #     type volume_name: String
    # * lun_id: LUN ID
    #     type lun_id: Integer
    # * host_name: Name of the host which the volume is exported. For VLUN of port type,the value is empty
    #     type host_name: String
    # * port: Specifies the system port of the VLUN export.  It includes the system node number, PCI bus slot number, and card port number on the FC card in the format<node>:<slot>:<cardPort>
    #     type port: Hash
    #
    #         port = {'node'=> 1,   # System node (0-7)
    #                 'slot'=> 2,   # PCI bus slot in the node (0-5)
    #                 'port'=>1}    # Port number on the FC card (0-4)
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #         - INV_INPUT_MISSING_REQUIRED - Incomplete VLUN info. Missing
    #         volumeName or lun, or both hostname and port.
    # * Hpe3parSdk::HTTPBadRequest
    #         - INV_INPUT_PORT_SELECTION - Specified port is invalid.
    # * Hpe3parSdk::HTTPBadRequest
    #         - INV_INPUT_EXCEEDS_RANGE - The LUN specified exceeds expected
    #         range.
    # * Hpe3parSdk::HTTPNotFound
    #         - NON_EXISTENT_HOST - The host does not exist
    # * Hpe3parSdk::HTTPNotFound
    #         - NON_EXISTENT_VLUN - The VLUN does not exist
    # * Hpe3parSdk::HTTPNotFound
    #         - NON_EXISTENT_PORT - The port does not exist
    # * Hpe3parSdk::HTTPForbidden
    #         - PERM_DENIED - Permission denied
    def delete_vlun(volume_name, lun_id, host_name = nil, port = nil)
      begin
        @vlun.delete_vlun(volume_name, lun_id, host_name, port)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets QoS Rules.
    #
    # ==== Returns
    #
    # Array of QoSRule objects
    #
    def query_qos_rules
      begin
        @qos.query_qos_rules
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end    
    end

    # Queries a QoS rule
    #
    # ==== Attributes
    #
    # * target_name : Name of the target. When targetType is sys, target name must be sys:all_others.
    #     type target_name: String
    # * target_type : Target type is vvset or sys
    #     type target_type: String
    # ==== Returns
    #
    # QoSRule object
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_QOS_RULE - QoS rule does not exist.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_ILLEGAL_CHAR - Illegal character in the input.
    def query_qos_rule(target_name, target_type = 'vvset')
      begin
        @qos.query_qos_rule(target_name, target_type)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    def qos_rule_exists?(target_name, target_type = 'vvset')
       begin
        @qos.qos_rule_exists?(target_name, target_type)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

     # Creates QOS rules

    # The QoS rule can be applied to VV sets. By using sys:all_others,
    # you can apply the rule to all volumes in the system for which no
    # QoS rule has been defined.
    # ioMinGoal and ioMaxLimit must be used together to set I/O limits.
    # Similarly, bwMinGoalKB and bwMaxLimitKB must be used together.
    # If ioMaxLimitOP is set to 2 (no limit), ioMinGoalOP must also be
    # to set to 2 (zero), and vice versa. They cannot be set to
    # 'none' individually. Similarly, if bwMaxLimitOP is set to 2 (no
    # limit), then bwMinGoalOP must also be set to 2.
    # If ioMaxLimitOP is set to 1 (no limit), ioMinGoalOP must also be
    # to set to 1 (zero) and vice versa. Similarly, if bwMaxLimitOP is
    # set to 1 (zero), then bwMinGoalOP must also be set to 1.
    # The ioMinGoalOP and ioMaxLimitOP fields take precedence over
    # the ioMinGoal and ioMaxLimit fields.
    # The bwMinGoalOP and bwMaxLimitOP fields take precedence over
    # the bwMinGoalKB and bwMaxLimitKB fields
    #
    # ==== Attributes
    #
    # * target_type: Type of QoS target, either enum TARGET_TYPE_VVS or TARGET_TYPE_SYS.
    #      type target_type:  VVSET or SYS. Refer QoStargetType::VVSET for complete enumeration 
    # * target_name: Name of the target object on which the QoS rule will be created.
    #      type target_name: String
    # * qos_rules: QoS options
    #     type qos_rules: Hash
    #     qos_rules = {
    #         'priority'=> 2,         # Refer Hpe3parSdk::QoSpriorityEnumeration for complete enumeration 
    #         'bwMinGoalKB'=> 1024,   # bandwidth rate minimum goal in
    #                                 #   kilobytes per second
    #         'bwMaxLimitKB'=> 1024,  # bandwidth rate maximum limit in
    #                                 #   kilobytes per second
    #         'ioMinGoal'=> 10000,    # I/O-per-second minimum goal
    #         'ioMaxLimit'=> 2000000, # I/0-per-second maximum limit
    #         'enable'=> false,        # QoS rule for target enabled?
    #         'bwMinGoalOP'=> 1,      # zero none operation enum, when set to
    #                                 #   1, bandwidth minimum goal is 0
    #                                 # when set to 2, the bandwidth mimumum
    #                                 #   goal is none (NoLimit)
    #         'bwMaxLimitOP'=> 1,     # zero none operation enum, when set to
    #                                 #   1, bandwidth maximum limit is 0
    #                                 # when set to 2, the bandwidth maximum
    #                                 #   limit is none (NoLimit)
    #         'ioMinGoalOP'=>1,       # zero none operation enum, when set to
    #                                 #   1, I/O minimum goal is 0
    #                                 # when set to 2, the I/O minimum goal is
    #                                 #   none (NoLimit)
    #         'ioMaxLimitOP'=> 1,     # zero none operation enum, when set to
    #                                 #   1, I/O maximum limit is 0
    #                                 # when set to 2, the I/O maximum limit
    #                                 #   is none (NoLimit)
    #         'latencyGoal'=>5000,    # Latency goal in milliseconds
    #         'defaultLatency'=> false# Use latencyGoal or defaultLatency?
    #     }
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_EXCEEDS_RANGE - Invalid input: number exceeds expected range.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_QOS_RULE - QoS rule does not exists.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_ILLEGAL_CHAR - Illegal character in the input.
    # * Hpe3parSdk::HTTPBadRequest
    #        - EXISTENT_QOS_RULE - QoS rule already exists.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_MIN_GOAL_GRT_MAX_LIMIT - I/O-per-second maximum limit should be greater than the minimum goal.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_BW_MIN_GOAL_GRT_MAX_LIMIT - Bandwidth maximum limit should be greater than the mimimum goal.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_BELOW_RANGE - I/O-per-second limit is below range.Bandwidth limit is below range.
    # * Hpe3parSdk::HTTPBadRequest
    #        - UNLICENSED_FEATURE - The system is not licensed for QoS.
    def create_qos_rules(target_name, qos_rules, target_type = QoStargetType::VVSET)
      if @current_version < @min_version && !qos_rules.nil?
        qos_rules.delete_if { |key, _value| key == :latencyGoaluSecs }
      end
      begin
        @qos.create_qos_rules(target_name, qos_rules, target_type)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Modifies an existing QOS rules
    #
    # The QoS rule can be applied to VV sets. By using sys:all_others,
    # you can apply the rule to all volumes in the system for which no
    # QoS rule has been defined.
    # ioMinGoal and ioMaxLimit must be used together to set I/O limits.
    # Similarly, bwMinGoalKB and bwMaxLimitKB must be used together.
    # If ioMaxLimitOP is set to 2 (no limit), ioMinGoalOP must also be
    # to set to 2 (zero), and vice versa. They cannot be set to
    # 'none' individually. Similarly, if bwMaxLimitOP is set to 2 (no
    # limit), then bwMinGoalOP must also be set to 2.
    # If ioMaxLimitOP is set to 1 (no limit), ioMinGoalOP must also be
    # to set to 1 (zero) and vice versa. Similarly, if bwMaxLimitOP is
    # set to 1 (zero), then bwMinGoalOP must also be set to 1.
    # The ioMinGoalOP and ioMaxLimitOP fields take precedence over
    # the ioMinGoal and ioMaxLimit fields.
    # The bwMinGoalOP and bwMaxLimitOP fields take precedence over
    # the bwMinGoalKB and bwMaxLimitKB fields
    #
    # ==== Attributes
    #
    # * target_name: Name of the target object on which the QoS rule will be created.
    #     type target_name: String
    # * target_type: Type of QoS target, either vvset or sys.Refer Hpe3parSdk::QoStargetTypeConstants for complete enumeration
    #     type target_type: String
    # * qos_rules: QoS options
    #     type qos_rules: Hash
    #     qos_rules = {
    #         'priority'=> 2,         # Refer Hpe3parSdk::QoSpriorityEnumeration for complete enumeration
    #         'bwMinGoalKB'=> 1024,   # bandwidth rate minimum goal in
    #                                 # kilobytes per second
    #         'bwMaxLimitKB'=> 1024,  # bandwidth rate maximum limit in
    #                                 # kilobytes per second
    #         'ioMinGoal'=> 10000,    # I/O-per-second minimum goal.
    #         'ioMaxLimit'=> 2000000, # I/0-per-second maximum limit
    #         'enable'=> True,        # QoS rule for target enabled?
    #         'bwMinGoalOP'=> 1,      # zero none operation enum, when set to
    #                                 # 1, bandwidth minimum goal is 0
    #                                 # when set to 2, the bandwidth minimum
    #                                 # goal is none (NoLimit)
    #         'bwMaxLimitOP'=> 1,     # zero none operation enum, when set to
    #                                 # 1, bandwidth maximum limit is 0
    #                                 # when set to 2, the bandwidth maximum
    #                                 # limit is none (NoLimit)
    #         'ioMinGoalOP'=> 1,      # zero none operation enum, when set to
    #                                 # 1, I/O minimum goal minimum goal is 0
    #                                 # when set to 2, the I/O minimum goal is
    #                                 # none (NoLimit)
    #         'ioMaxLimitOP'=> 1,     # zero none operation enum, when set to
    #                                 # 1, I/O maximum limit is 0
    #                                 # when set to 2, the I/O maximum limit
    #                                 # is none (NoLimit)
    #         'latencyGoal'=> 5000,   # Latency goal in milliseconds
    #         'defaultLatency'=> false# Use latencyGoal or defaultLatency?
    #     }
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #     INV_INPUT_EXCEEDS_RANGE - Invalid input: number exceeds expected
    #     range.
    # * Hpe3parSdk::HTTPNotFound
    #     NON_EXISTENT_QOS_RULE - QoS rule does not exists.
    # * Hpe3parSdk::HTTPBadRequest
    #     INV_INPUT_ILLEGAL_CHAR - Illegal character in the input.
    # * Hpe3parSdk::HTTPBadRequest
    #     EXISTENT_QOS_RULE - QoS rule already exists.
    # * Hpe3parSdk::HTTPBadRequest
    #     INV_INPUT_IO_MIN_GOAL_GRT_MAX_LIMIT - I/O-per-second maximum limit
    #     should be greater than the minimum goal.
    # * Hpe3parSdk::HTTPBadRequest
    #     INV_INPUT_BW_MIN_GOAL_GRT_MAX_LIMIT - Bandwidth maximum limit
    #     should be greater than the minimum goal.
    # * Hpe3parSdk::HTTPBadRequest
    #     INV_INPUT_BELOW_RANGE - I/O-per-second limit is below
    #     range. Bandwidth limit is below range.
    # * Hpe3parSdk::HTTPBadRequest
    #              UNLICENSED_FEATURE - The system is not licensed for QoS.
    def modify_qos_rules(target_name, qos_rules, target_type = QoStargetTypeConstants::VVSET)
      if @current_version < @min_version && !qos_rules.nil?
        qos_rules.delete_if { |key, _value| key == :latencyGoaluSecs }
      end
      begin
        @qos.modify_qos_rules(target_name, qos_rules, target_type)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Deletes QoS rules.
    #
    # ==== Attributes
    #
    # * target_name: Name of the target. When target_type is sys, target_name must be sys:all_others.
    #     type target_name: String
    # * target_type: target type is vvset or sys
    #     type target_type: String
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPNotFound
    #                     NON_EXISTENT_QOS_RULE - QoS rule does not exist.
    # * Hpe3parSdk::HTTPBadRequest
    #                     INV_INPUT_ILLEGAL_CHAR - Illegal character in the input
    def delete_qos_rules(target_name, target_type = QoStargetTypeConstants::VVSET)
      begin
        @qos.delete_qos_rules(target_name, target_type)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets all hosts.
    #
    # ==== Returns
    #
    # Array of Host.
    def get_hosts
      begin
        @host.get_hosts
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets host information by name.
    #
    # ==== Attributes
    #
    # * name - The name of the host to find.
    #      type name: String
    #
    # ==== Returns
    #
    # Host.
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #       - INV_INPUT - Invalid URI syntax.
    # * Hpe3parSdk::HTTPNotFound
    #       - NON_EXISTENT_HOST - Host not found.
    # * Hpe3parSdk::HTTPInternalServerError
    #       - INT_SERV_ERR - Internal server error.
    # * Hpe3parSdk::HTTPBadRequest
    #       - INV_INPUT_ILLEGAL_CHAR - Host name contains invalid character.
    def get_host(name)
      begin
        @host.get_host(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Creates a new Host.
    #
    # ==== Attributes
    #
    # * name - The name of the host.
    #      type name: String
    # * iscsi_names - Array of iSCSI iqns.
    #      type iscsi_names: Array
    # * fcwwns - Array of Fibre Channel World Wide Names.
    #      type fcwwns: Array
    # * optional - The optional stuff.
    #      type optional: Hash
    #        optional = {
    #            'persona'=> 1,                  # Refer Hpe3parSdk::HostPersona for complete enumeration.
    #                                            # 3.1.3 default: Generic-ALUA
    #                                            # 3.1.2 default: General
    #            'domain'=> 'myDomain',          # Create the host in the
    #                                            # specified domain, or default
    #                                            # domain if unspecified.
    #            'forceTearDown'=> false,        # If True, force to tear down
    #                                            # low-priority VLUN exports.
    #            'descriptors'=>
    #                {'location'=> 'earth',      # The host's location
    #                 'IPAddr'=> '10.10.10.10',  # The host's IP address
    #                 'os'=> 'linux',            # The operating system running on the host.
    #                 'model'=> 'ex',            # The host's model
    #                 'contact'=> 'Smith',       # The host's owner and contact
    #                 'comment'=> "Joe's box"}   # Additional host information
    #        }
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPForbidden
    #        - PERM_DENIED - Permission denied.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_MISSING_REQUIRED - Name not specified.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_PARAM_CONFLICT - FCWWNs and iSCSINames are both specified.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_EXCEEDS_LENGTH - Host name, domain name, or iSCSI name is too long.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_EMPTY_STR - Input string (for domain name, iSCSI name, etc.) is empty.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_ILLEGAL_CHAR - Any error from host-name or domain-name parsing.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_TOO_MANY_WWN_OR_iSCSI - More than 1024 WWNs or iSCSI names are specified.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_WRONG_TYPE - The length of WWN is not 16. WWN specification contains non-hexadecimal digit.
    # * Hpe3parSdk::HTTPConflict
    #        - EXISTENT_PATH - host WWN/iSCSI name already used by another host.
    # * Hpe3parSdk::HTTPConflict
    #        - EXISTENT_HOST - host name is already used.
    # * Hpe3parSdk::HTTPBadRequest
    #        - NO_SPACE - No space to create host.
    def create_host(name, iscsi_names = nil, fcwwns = nil, optional = nil)
      begin
        @host.create_host(name, iscsi_names, fcwwns, optional)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Modifies an existing Host.
    #
    # ==== Attributes
    #
    # * name - Name of the host.
    #      type name: String
    # * mod_request - Objects for host modification request.
    #      type mod_request: Hash
    #        mod_request = {
    #            'newName'=> 'myNewName',         # New name of the host
    #            'pathOperation'=> 1,             # Refer Hpe3parSdk::HostEditOperation for complete enumeration
    #            'FCWWNs'=> [],                   # One or more WWN to set for the host.
    #            'iSCSINames'=> [],               # One or more iSCSI names to set for the host.
    #            'forcePathRemoval'=> false,      # If True, remove SSN(s) or
    #                                             # iSCSI(s) even if there are
    #                                             # VLUNs exported to host
    #            'persona'=> 1,                   # Refer Hpe3parSdk::HostPersona for complete enumeration.
    #            'descriptors'=>
    #                {'location'=> 'earth',       # The host's location
    #                 'IPAddr'=> '10.10.10.10',   # The host's IP address
    #                 'os'=> 'linux',             # The operating system running on the host.
    #                 'model'=> 'ex',             # The host's model
    #                 'contact'=> 'Smith',        # The host's owner and contact
    #                 'comment'=> 'Joes box'}     # Additional host information
    #            'chapOperation'=> 1,             # Refer Hpe3parSdk::HostEditOperation for complete enumeration
    #            'chapOperationMode'=> TARGET,    # Refer Hpe3parSdk::ChapOperationMode for complete enumeration
    #            'chapName'=> 'MyChapName',       # The chap name
    #            'chapSecret'=> 'xyz',            # The chap secret for the host or the target
    #            'chapSecretHex'=> false,         # If True, the chapSecret is treated as Hex.
    #            'chapRemoveTargetOnly'=> true    # If True, then remove target chap only
    #        }
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT - Missing host name.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_PARAM_CONFLICT - Both iSCSINames & FCWWNs are specified. (lot of other possibilities).
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_ONE_REQUIRED - iSCSINames or FCWwns missing.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_ONE_REQUIRED - No path operation specified.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_BAD_ENUM_VALUE - Invalid enum value.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_MISSING_REQUIRED - Required fields missing.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_EXCEEDS_LENGTH - Host descriptor argument length, new host name, or iSCSI name is too long.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_ILLEGAL_CHAR - Error parsing host or iSCSI name.
    # * Hpe3parSdk::HTTPConflict
    #        - EXISTENT_HOST - New host name is already used.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_HOST - Host to be modified does not exist.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_TOO_MANY_WWN_OR_iSCSI - More than 1024 WWNs or iSCSI names are specified.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_WRONG_TYPE - Input value is of the wrong type.
    # * Hpe3parSdk::HTTPConflict
    #        - EXISTENT_PATH - WWN or iSCSI name is already claimed by other host.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_BAD_LENGTH - CHAP hex secret length is not 16 bytes, or chap ASCII secret length is not 12 to 16 characters.
    # * Hpe3parSdk::HTTPNotFound
    #        - NO_INITIATOR_CHAP - Setting target CHAP without initiator CHAP.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_CHAP - Remove non-existing CHAP.
    # * Hpe3parSdk::HTTPConflict
    #        - NON_UNIQUE_CHAP_SECRET - CHAP secret is not unique.
    # * Hpe3parSdk::HTTPConflict
    #        - EXPORTED_VLUN - Setting persona with active export; remove a host path on an active export.
    # * Hpe3parSdk::HTTPBadRequest
    #        - NON_EXISTENT_PATH - Remove a non-existing path.
    # * Hpe3parSdk::HTTPConflict
    #        - LUN_HOSTPERSONA_CONFLICT - LUN number and persona capability conflict.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_DUP_PATH - Duplicate path specified.
    def modify_host(name, mod_request)
      begin
        @host.modify_host(name, mod_request)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Deletes a host.
    #
    # ==== Attributes
    #
    # * name - The name of host to be deleted.
    #      type name: String
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_HOST - Host not found
    # * Hpe3parSdk::HTTPConflict
    #        -  HOST_IN_SET - Host is a member of a set
    def delete_host(name)
      begin
        @host.delete_host(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Finds the host with the specified FC WWN path.
    #
    # ==== Attributes
    #
    # * wwn - Lookup based on WWN.
    #      type wwn: String
    #
    # ==== Returns
    #
    # Host with specified FC WWN.
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT - Invalid URI syntax.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_HOST - HOST Not Found
    # * Hpe3parSdk::HTTPInternalServerError
    #        - INTERNAL_SERVER_ERR - Internal server error.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_ILLEGAL_CHAR - Host name contains invalid character.
    def query_host_by_fc_path(wwn = nil)
      begin
        @host.query_host_by_fc_path(wwn)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Finds the host with the specified iSCSI initiator.
    #
    # ==== Attributes
    #
    # * iqn - Lookup based on iSCSI initiator.
    #      type iqn: String
    #
    # ==== Returns
    #
    # Host with specified IQN.
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT - Invalid URI syntax.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_HOST - The specified host not found.
    # * Hpe3parSdk::HTTPInternalServerError
    #        - INTERNAL_SERVER_ERR - Internal server error.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_ILLEGAL_CHAR - The host name contains invalid character.
    def query_host_by_iscsi_path(iqn = nil)
      begin
        @host.query_host_by_iscsi_path(iqn)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets all host sets.
    #
    # ==== Returns
    #
    # Array of HostSet.
    def get_host_sets
      begin
        @host_set.get_host_sets
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Creates a new HostSet.
    #
    # ==== Attributes
    #
    # * name - Name of the host set to be created.
    #      type name: String
    # * domain - The domain in which the host set will be created.
    #      type domain: String
    # * comment - Comment for the host set.
    #      type comment: String
    # * setmembers - The hosts to be added to the set. The existence of the host will not be checked.
    #      type setmembers: Array of String
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - EXISTENT_SET - The set already exits.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_DOMAIN - The domain does not exist.
    # * Hpe3parSdk::HTTPConflict
    #        - MEMBER_IN_DOMAINSET - The host is in a domain set.
    # * Hpe3parSdk::HTTPConflict
    #        - MEMBER_IN_SET - The object is already part of the set.
    # * Hpe3parSdk::HTTPConflict
    #        - MEMBER_NOT_IN_SAME_DOMAIN - Objects must be in the same domain to perform this operation.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_HOST - The host does not exists.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_DUP_NAME - Invalid input (duplicate name).
    def create_host_set(name, domain = nil, comment = nil, setmembers = nil)
      begin
        @host_set.create_host_set(name, domain, comment, setmembers)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Deletes a HostSet.
    #
    # ==== Attributes
    #
    # * name - The hostset to delete.
    #      type name: String
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_SET - The set does not exists.
    # * Hpe3parSdk::HTTPConflict
    #        - EXPORTED_VLUN - The host set has exported VLUNs.
    def delete_host_set(name)
      begin
        @host_set.delete_host_set(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Modifies a HostSet.
    #
    # ==== Attributes
    #
    # * name - Hostset name
    #      type name: String
    # * action - Add or Remove host(s) from the set
    #      type action: Refer values of Hpe3parSdk::SetCustomAction::MEM_ADD and Hpe3parSdk::SetCustomAction::MEM_REMOVE
    # * setmembers - Host(s) to add to the set, the existence of the host(s) will not be checked
    #      type setmembers: Array of String
    # * new_name - New name of set
    #      type new_name: String
    # * comment - New comment for the set
    #      type comment: String
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - EXISTENT_SET - The set already exits.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_SET - The set does not exists.
    # * Hpe3parSdk::HTTPConflict
    #        - MEMBER_IN_DOMAINSET - The host is in a domain set.
    # * Hpe3parSdk::HTTPConflict
    #        - MEMBER_IN_SET - The object is already part of the set.
    # * Hpe3parSdk::HTTPNotFound
    #        - MEMBER_NOT_IN_SET - The object is not part of the set.
    # * Hpe3parSdk::HTTPConflict
    #        - MEMBER_NOT_IN_SAME_DOMAIN - Objects must be in the same domain to perform this operation.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_DUP_NAME - Invalid input (duplicate name).
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_PARAM_CONFLICT - Invalid input (parameters cannot be present at the same time).
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_ILLEGAL_CHAR - Invalid contains one or more illegal characters.
    def modify_host_set(name, action = nil, setmembers = nil, new_name = nil, comment = nil)
      begin
        @host_set.modify_host_set(name, action, setmembers, new_name, comment)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Adds host(s) to a host set.
    #
    # ==== Attributes
    #
    # * set_name - Hostset name.
    #      type set_name: String
    # * setmembers - Array of host names to add to the set.
    #      type setmembers: Array of String
    def add_hosts_to_host_set(set_name, setmembers)
      begin
        @host_set.add_hosts_to_host_set(set_name, setmembers)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Removes host(s) from a host set.
    #
    # ==== Attributes
    #
    # * set_name - The host set name.
    #      type set_name: String
    # * setmembers - Array of host names to remove from the set.
    #      type setmembers: Array of String
    def remove_hosts_from_host_set(set_name, setmembers)
      begin
        @host_set.remove_hosts_from_host_set(set_name, setmembers)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Returns an array of every Hostset the given host is a part of. The array can contain zero, one, or multiple items.
    #
    # ==== Attributes
    #
    # * host_name - The host name of whose hostset is to be found.
    #      type host_name: String
    #
    # ==== Returns
    #
    # Array of HostSet.
    def find_host_sets(host_name)
      begin
        @host_set.find_host_sets(host_name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets hostset information by name.
    #
    # ==== Attributes
    #
    # * name - The name of the hostset to find.
    #      type name: String
    #
    # ==== Returns
    #
    # HostSet.
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_SET - The set does not exist.
    def get_host_set(name)
      begin
        @host_set.get_host_set(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets all of the VLUNs on a specific host.
    #
    # ==== Attributes
    #
    # * host_name - Name of the host.
    #      type host_name: String
    #
    # ==== Returns
    #
    # Array of VLUN.
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_HOST - The specified host not found.
    def get_host_vluns(host_name)
      begin
        @host.get_host_vluns(host_name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets all Volumes in the array
    #
    # ==== Returns
    #
    # Array of VirtualVolume 
    def get_volumes
      begin
        @volume.get_volumes(VolumeCopyType::BASE_VOLUME)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets the list of snapshots in the array
    #
    # ==== Returns
    #
    # Array of VirtualVolume 
    def get_snapshots
      begin
        @volume.get_volumes(VolumeCopyType::VIRTUAL_COPY)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets information about a volume by name
    #
    # ==== Attributes
    #
    # * name - The name of the volume to find
    #    type name: String
    #
    # ==== Returns
    #
    # VirtualVolume
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HPE3PARException
    #       Error with code: 23 message: volume does not exist
    def get_volume(name)
      begin
        @volume.get_volume(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets information about a volume by wwn
    #
    # ==== Attributes
    #
    # * wwn - The wwn of the volume to find
    #    type wwn: String
    #
    # ==== Returns
    #
    # * VirtualVolume
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HPE3PARException
    #       Error with code: 23 message: volume does not exist
    def get_volume_by_wwn(wwn)
      begin
        @volume.get_volume_by_wwn(wwn)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Creates a new volume.
    #
    # ==== Attributes
    #
    # * name - the name of the volume
    #      type name: String
    # * cpg_name - the name of the destination CPG
    #      type cpg_name: String
    # * size_MiB - size in MiB for the volume
    #      type size_MiB: Integer
    # * optional - hash of other optional items
    #      type optional: hash
    #
    #      optional = {
    #         'id' => 12,                     # Volume ID. If not specified, next
    #                                         # available is chosen
    #         'comment' => 'some comment',    # Additional information up to 511
    #                                         # characters
    #         'policies: {                    # Specifies VV policies
    #            'staleSS' => false,          # True allows stale snapshots.
    #            'oneHost' => true,           # True constrains volume export to
    #                                         # single host or host cluster
    #            'zeroDetect' => true,        # True requests Storage System to
    #                                         # scan for zeros in incoming write
    #                                         # data
    #            'system' => false,           # True special volume used by system
    #                                         # False is normal user volume
    #            'caching' => true},          # Read-only. True indicates write &
    #                                         # read caching & read ahead enabled
    #         'snapCPG' => 'CPG name',        # CPG Used for snapshots
    #         'ssSpcAllocWarningPct' => 12,   # Snapshot space allocation warning
    #         'ssSpcAllocLimitPct' => 22,     # Snapshot space allocation limit
    #         'tpvv' => true,                 # True: Create TPVV
    #                                         # False (default) Create FPVV
    #         'usrSpcAllocWarningPct' => 22,  # Enable user space allocation
    #                                         # warning
    #         'usrSpcAllocLimitPct' => 22,    # User space allocation limit
    #         'expirationHours' => 256,       # Relative time from now to expire
    #                                         # volume (max 43,800 hours)
    #         'retentionHours' => 256         # Relative time from now to retain
    #    }
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT - Invalid Parameter
    # * Hpe3parSdk::HTTPBadRequest
    #        - TOO_LARGE - Volume size above limit
    # * Hpe3parSdk::HTTPBadRequest
    #        - NO_SPACE - Not Enough space is available
    # * Hpe3parSdk::HTTPForbidden
    #        - PERM_DENIED - Permission denied
    # * Hpe3parSdk::HTTPConflict
    #        - EXISTENT_SV - Volume Exists already
    def create_volume(name, cpg_name, size_MiB, optional = nil)
      if @current_version < @min_version_with_compression && !optional.nil?
        optional.delete_if { |key, _value| key == :compression }
      end
      begin
        @volume.create_volume(name, cpg_name, size_MiB, optional)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Deletes a volume
    #
    # ==== Attributes
    #
    # * name - the name of the volume
    #      type name: String
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_VOL - The volume does not exist
    # * Hpe3parSdk::HTTPForbidden
    #        - PERM_DENIED - Permission denied
    # * Hpe3parSdk::HTTPForbidden
    #        - RETAINED - Volume retention time has not expired
    # * Hpe3parSdk::HTTPForbidden
    #        - HAS_RO_CHILD - Volume has read-only child
    # * Hpe3parSdk::HTTPConflict
    #        - HAS_CHILD - The volume has a child volume
    # * Hpe3parSdk::HTTPConflict
    #        - IN_USE - The volume is in use by VV set, VLUN, etc
    def delete_volume(name)
      begin
        @volume.delete_volume(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Modifies a volume
    #
    # ==== Attributes
    #
    # * name - the name of the volume
    #      type name: String
    # * volumeMods - Hash of volume attributes to change
    #      type volumeMods: Hash
    #       volumeMods = {
    #         'newName' => 'newName',           # New volume name
    #         'comment' => 'some comment',      # New volume comment
    #         'snapCPG' => 'CPG name',          # Snapshot CPG name
    #         'policies: {                      # Specifies VV policies
    #            'staleSS' => false,            # True allows stale snapshots.
    #            'oneHost' => true,             # True constrains volume export to
    #                                           # single host or host cluster
    #            'zeroDetect' => true,          # True requests Storage System to
    #                                           # scan for zeros in incoming write
    #                                           # data
    #            'system' => false,             # True special volume used by system
    #                                           # False is normal user volume
    #            'caching' => true},            # Read-only. True indicates write &
    #                                           # read caching & read ahead enabled
    #         'ssSpcAllocWarningPct' => 12,     # Snapshot space allocation warning
    #         'ssSpcAllocLimitPct' => 22,       # Snapshot space allocation limit
    #         'tpvv' => true,                   # True: Create TPVV
    #                                           # False: (default) Create FPVV
    #         'usrSpcAllocWarningPct' => 22,    # Enable user space allocation
    #                                           # warning
    #         'usrSpcAllocLimitPct' => 22,      # User space allocation limit
    #         'userCPG' => 'User CPG name',     # User CPG name
    #         'expirationHours' => 256,         # Relative time from now to expire
    #                                           # volume (max 43,800 hours)
    #         'retentionHours' => 256,          # Relative time from now to retain
    #                                           # volume (max 43,800 hours)
    #         'rmSsSpcAllocWarning' => false,   # True removes snapshot space
    #                                           # allocation warning.
    #                                           # False sets it when value > 0
    #         'rmUsrSpcAllocWarwaning' => false,# True removes user space
    #                                           #  allocation warning.
    #                                           # False sets it when value > 0
    #         'rmExpTime' => false,             # True resets expiration time to 0.
    #                                           # False sets it when value > 0
    #         'rmSsSpcAllocLimit' => false,     # True removes snapshot space
    #                                           # allocation limit.
    #                                           # False sets it when value > 0
    #         'rmUsrSpcAllocLimit' => false     # True removes user space
    #                                           # allocation limit.
    #                                           # False sets it when value > 0
    #        }
    #
    # ==== Raises:
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_WARN_GT_LIMIT - Allocation warning level is higher than
    #        the limit.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_USR_ALRT_NON_TPVV - User space allocation alerts are
    #        valid only with a TPVV.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_RETAIN_GT_EXPIRE - Retention time is greater than
    #        expiration time.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_VV_POLICY - Invalid policy specification (for example,
    #        caching or system is set to true).
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_EXCEEDS_LENGTH - Invalid input: string length exceeds
    #        limit.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_TIME - Invalid time specified.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_MODIFY_USR_CPG_TPVV - usr_cpg cannot be modified
    #        on a TPVV.
    # * Hpe3parSdk::HTTPBadRequest
    #        - UNLICENSED_FEATURE - Retention time cannot be modified on a
    #        system without the Virtual Lock license.
    # * Hpe3parSdk::HTTPForbidden
    #        - CPG_NOT_IN_SAME_DOMAIN - Snap CPG is not in the same domain as
    #        the user CPG.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_PEER_VOLUME - Cannot modify a peer volume.
    # * Hpe3parSdk::HTTPInternalServerError
    #        - INT_SERV_ERR - Metadata of the VV is corrupted.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_SYS_VOLUME - Cannot modify retention time on a
    #        system volume.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_INTERNAL_VOLUME - Cannot modify an internal
    #        volume
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_VOLUME_NOT_DEFINED_ALL_NODES - Cannot modify a
    #        volume until the volume is defined on all volumes.
    # * Hpe3parSdk::HTTPConflict
    #        - INVALID_OPERATION_VV_ONLINE_COPY_IN_PROGRESS - Cannot modify a
    #        volume when an online copy for that volume is in progress.
    # * Hpe3parSdk::HTTPConflict
    #        - INVALID_OPERATION_VV_VOLUME_CONV_IN_PROGRESS - Cannot modify a
    #        volume in the middle of a conversion operation.
    # * Hpe3parSdk::HTTPConflict
    #        - INVALID_OPERATION_VV_SNAPSPACE_NOT_MOVED_TO_CPG - Snapshot space
    #        of a volume needs to be moved to a CPG before the user space.
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_VOLUME_ACCOUNTING_IN_PROGRESS - The volume
    #        cannot be renamed until snapshot accounting has finished.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_ZERO_DETECT_TPVV - The zero_detect policy can be
    #        used only on TPVVs.
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_CPG_ON_SNAPSHOT - CPG cannot be assigned to a
    #        snapshot.
    def modify_volume(name, volume_mods)
      begin
        @volume.modify_volume(name, volume_mods)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Grows an existing volume by 'amount' Mebibytes.
    #
    # ==== Attributes
    #
    # * name - the name of the volume
    #      type name: String
    # * amount: the additional size in MiB to add, rounded up to the next chunklet size (e.g. 256 or 1000 MiB)
    #      type amount: Integer
    #
    # ==== Raises:
    #
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_NOT_IN_SAME_DOMAIN - The volume is not in the same domain.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_VOL - The volume does not exist.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_UNSUPPORTED_VV_TYPE - Invalid operation: Cannot
    #        grow this type of volume.
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_TUNE_IN_PROGRESS - Invalid operation: Volume
    #       tuning is in progress.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_EXCEEDS_LENGTH - Invalid input: String length exceeds
    #        limit.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_VV_GROW_SIZE - Invalid grow size.
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_NEW_SIZE_EXCEEDS_CPG_LIMIT - New volume size exceeds CPG limit
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_INTERNAL_VOLUME - This operation is not allowed
    #        on an internal volume.
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_VOLUME_CONV_IN_PROGRESS - Invalid operation: VV
    #        conversion is in progress.
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_VOLUME_COPY_IN_PROGRESS - Invalid operation:
    #        online copy is in progress.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_CLEANUP_IN_PROGRESS - Internal volume cleanup is
    #        in progress.
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_IS_BEING_REMOVED - The volume is being removed.
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_IN_INCONSISTENT_STATE - The volume has an internal consistency
    #        error.
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_SIZE_CANNOT_REDUCE - New volume size is smaller than the
    #        current size.
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_NEW_SIZE_EXCEEDS_LIMITS - New volume size exceeds the limit.
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_SA_SD_SPACE_REMOVED - Invalid operation: Volume
    #        SA/SD space is being removed.
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_IS_BUSY - Invalid operation: Volume is currently
    #        busy.
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_NOT_STARTED - Volume is not started.
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_IS_PCOPY - Invalid operation: Volume is a
    #        physical copy.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_NOT_IN_NORMAL_STATE - Volume state is not normal
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_PROMOTE_IN_PROGRESS - Invalid operation: Volume
    #        promotion is in progress.
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_PARENT_OF_PCOPY - Invalid operation: Volume is
    #        the parent of physical copy.
    # * Hpe3parSdk::HTTPBadRequest
    #        - NO_SPACE - Insufficent space for requested operation.
    def grow_volume(name, amount)
      begin
        @volume.grow_volume(name, amount)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Creates a physical copy of a VirtualVolume
    #
    # ==== Attributes
    #
    # * src_name - the source volume name
    #      type src_name: String
    # * dest_name - the destination volume name
    #      type dest_name: String
    # * dest_cpg - the destination CPG
    #      type dest_cpg: String
    # * optional - Hash of optional parameters
    #      type optional: Hash
    #
    #      optional = {
    #       'online' => false,                # should physical copy be
    #                                         # performed online?
    #       'tpvv' => false,                  # use thin provisioned space
    #                                         # for destination
    #                                         # (online copy only)
    #       'snapCPG' => 'OpenStack_SnapCPG', # snapshot CPG for the
    #                                         # destination
    #                                         # (online copy only)
    #       'saveSnapshot' => false,          # save the snapshot of the
    #                                         # source volume
    #       'priority' => 1                   # taskPriorityEnum (does not
    #                                         # apply to online copy - Hpe3parSdk::TaskPriority)
    #      }
    def create_physical_copy(src_name, dest_name, dest_cpg, optional = nil)
      if @current_version < @min_version_with_compression && !optional.nil?
        [:compression, :allowRemoteCopyParent, :skipZero].each { |key| optional.delete key }
      end
      begin
        @volume.create_physical_copy(src_name, dest_name, dest_cpg, optional)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Deletes a physical copy
    #
    # ==== Attributes
    #
    # * name - the name of the clone volume
    #      type name: String
    #
    # ==== Raises:
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_VOL - The volume does not exist
    # * Hpe3parSdk::HTTPForbidden
    #        - PERM_DENIED - Permission denied
    # * Hpe3parSdk::HTTPForbidden
    #        - RETAINED - Volume retention time has not expired
    # * Hpe3parSdk::HTTPForbidden
    #        - HAS_RO_CHILD - Volume has read-only child
    # * Hpe3parSdk::HTTPConflict
    #        - HAS_CHILD - The volume has a child volume
    # * Hpe3parSdk::HTTPConflict
    #        - IN_USE - The volume is in use by VV set, VLUN, etc
    def delete_physical_copy(name)
      begin
        @volume.delete_volume(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Tunes a volume
    #
    # ==== Attributes
    #
    # * name - the volume name
    #      type name: String
    # * tune_operation - Enum of tune operation - 1: Change User CPG, 2: Change snap CPG
    #      type dest_name: Integer
    # * optional - hash of optional parameters
    #      type optional: hash
    #
    #      optional = {
    #       'userCPG' => 'user_cpg',        # Specifies the new user
    #                                       # CPG to which the volume
    #                                       # will be tuned.
    #       'snapCPG' => 'snap_cpg',        # Specifies the snap CPG to
    #                                       # which the volume will be
    #                                       # tuned.
    #       'conversionOperation' => 1,     # conversion operation enum. Refer Hpe3parSdk::VolumeConversionOperation
    #       'keepVV' => 'new_volume',       # Name of the new volume
    #                                       # where the original logical disks are saved.
    #       'compression' => true           # Enables (true) or disables (false) compression.
    #                                       # You cannot compress a fully provisioned volume.
    #      }
    def tune_volume(name, tune_operation, optional = nil)
      if @current_version < @min_version_with_compression && !optional.nil?
        optional.delete_if { |key, _value| key == :compression }
      end
      begin
        object_hash = @volume.tune_volume(name, tune_operation, optional)
        get_task(object_hash['taskid'])
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Returns an array of every VolumeSet the given volume is a part of.
    # The array can contain zero, one, or multiple items.
    #
    # ==== Attributes
    #
    # * name - the volume name
    #      type name: String
    #
    # ==== Returns
    #
    # Array of VolumeSet
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPForbidden
    #       - VV_IN_INCONSISTENT_STATE - Internal inconsistency error in vol
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_IS_BEING_REMOVED - The volume is being removed
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_VOLUME - The volume does not exists
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_SYS_VOLUME - Illegal op on system vol
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_INTERNAL_VOLUME - Illegal op on internal vol
    def find_all_volume_sets(name)
      begin
        @volume_set.find_all_volume_sets(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets the Volume Sets
    #
    # ==== Returns
    #
    # Array of VolumeSet
    def get_volume_sets
      begin
        @volume_set.get_volume_sets
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets the information about a Volume Set.
    #
    # ==== Attributes
    #
    # * name - The name of the CPG to find
    #      type name: String
    #
    # ==== Returns
    #
    # VolumeSet
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HPE3PARException
    #       Error with code: 102 message: Set does not exist
    def get_volume_set(name)
      begin
        @volume_set.get_volume_set(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Creates a new volume set
    #
    # ==== Attributes
    #
    # * name - the volume set to create
    #      type name: String
    # * domain: the domain where the set lives
    #      type domain: String
    # * comment: the comment for the vv set
    #      type comment: String
    # * setmembers: the vv(s) to add to the set, the existence of the vv(s) will not be checked
    #      type name: Array of String
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT Invalid URI Syntax.
    # * Hpe3parSdk::HTTPBadRequest
    #        - NON_EXISTENT_DOMAIN - Domain doesn't exist.
    # * Hpe3parSdk::HTTPBadRequest
    #        - NO_SPACE - Not Enough space is available.
    # * Hpe3parSdk::HTTPBadRequest
    #        - BAD_CPG_PATTERN  A Pattern in a CPG specifies illegal values.
    # * Hpe3parSdk::HTTPForbidden
    #        - PERM_DENIED - Permission denied
    # * Hpe3parSdk::HTTPConflict
    #        - EXISTENT_CPG - CPG Exists already
    def create_volume_set(name, domain = nil, comment = nil, setmembers = nil)
      begin
        @volume_set.create_volume_set(name, domain, comment, setmembers)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Deletes the volume set. You must clear all QOS rules before a volume set can be deleted.
    #
    # ==== Attributes
    #
    # * name - The name of the VolumeSet
    #      type name: String
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPNotFound
    #       - NON_EXISTENT_SET - The set does not exists.
    # * Hpe3parSdk::HTTPConflict
    #        -  - EXPORTED_VLUN - The host set has exported VLUNs. The VV set was exported.
    # * Hpe3parSdk::HTTPConflict
    #        - VVSET_QOS_TARGET - The object is already part of the set.
    def delete_volume_set(name)
      begin
        @volume_set.delete_volume_set(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Modifies a volume set by adding or removing a volume from the volume
    # set. It's actions is based on the enums MEM_ADD or MEM_REMOVE.
    #
    # ==== Attributes
    #
    # * action: add or remove volume from the set
    #      type name: Hpe3parSdk::SetCustomAction
    # * name: the volume set name
    #      type name: String
    # * newName: new name of set
    #      type newName: String
    # * comment: the comment for on the vv set
    #      type comment: String
    # * flash_cache_policy: the flash-cache policy for the vv set
    #      type flash_cache_policy: enum
    # * setmembers: the vv to add to the set, the existence of the vv will not be checked
    #      type name: Array of String
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - EXISTENT_SET - The set already exits.
    # * Hpe3parSdk::HTTPBadRequest
    #        - EXISTENT_SET - The set already exits.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_SET - The set does not exists.
    # * Hpe3parSdk::HTTPConflict
    #        - MEMBER_IN_DOMAINSET - The host is in a domain set.
    # * Hpe3parSdk::HTTPConflict
    #        - MEMBER_IN_SET - The object is already part of the set.
    # * Hpe3parSdk::HTTPNotFound
    #        - MEMBER_NOT_IN_SET - The object is not part of the set.
    # * Hpe3parSdk::HTTPConflict
    #        - MEMBER_NOT_IN_SAME_DOMAIN - Objects must be in the same domain to
    #        perform this operation.
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_IN_INCONSISTENT_STATE - The volume has an internal
    #        inconsistency error.
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_IS_BEING_REMOVED - The volume is being removed.
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_VOLUME - The volume does not exists.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_SYS_VOLUME - The operation is not allowed on a
    #        system volume.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_INTERNAL_VOLUME - The operation is not allowed
    #        on an internal volume.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_DUP_NAME - Invalid input (duplicate name).
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_PARAM_CONFLICT - Invalid input (parameters cannot be
    #        present at the same time).
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_ILLEGAL_CHAR - Invalid contains one or more illegal
    #        characters.
    def modify_volume_set(name, action = nil, newName = nil, comment = nil, flash_cache_policy = nil, setmembers = nil)
      begin
        @volume_set.modify_volume_set(name, action, newName, comment, flash_cache_policy, setmembers)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end


    # Adds volume(s) to a volume set.
    #
    # ==== Attributes
    #
    # * set_name - the volume set name
    #      type set_name: String
    # * setmembers - the volume(s) name to add
    #      type setmembers: Array of String
    def add_volumes_to_volume_set(set_name, setmembers)
      begin
        @volume_set.add_volumes_to_volume_set(set_name, setmembers)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Removes a volume from a volume set
    #
    # ==== Attributes
    #
    # * set_name - the volume set name
    #      type set_name: String
    # * name - the volume name to remove
    #      type name: String
    def remove_volumes_from_volume_set(set_name, setmembers)
      begin
        @volume_set.remove_volumes_from_volume_set(set_name, setmembers)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Creates a snapshot of an existing VolumeSet
    #
    # ==== Attributes
    #
    # * name: Name of the Snapshot. The vvname pattern is described in "VV Name Patterns" in the HPE 3PAR Command Line Interface Reference, which is available at the following website: http://www.hp.com/go/storage/docs
    #      type name: String
    # * copy_of_name: the name of the parent volume
    #      type copy_of_name: String
    # * comment: the comment on the vv set
    #      type comment: String
    # * optional: Hash of optional params
    #      type optional: Hash   
    #      optional = {
    #       'id' => 12,                   # Specifies ID of the volume set
    #                                     # set, next by default
    #      'comment' => "some comment",
    #      'readOnly' => true,            # Read Only
    #      'expirationHours' => 36,       # time from now to expire
    #      'retentionHours' => 12         # time from now to expire
    #      }
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - INVALID_INPUT_VV_PATTERN - Invalid volume pattern specified
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_SET - The set does not exists.
    # * Hpe3parSdk::HTTPNotFound
    #        - EMPTY_SET - The set is empty
    # * Hpe3parSdk::HTTPServiceUnavailable  
    #        - VV_LIMIT_REACHED - Maximum number of volumes reached
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_VOL - The storage volume does not exist
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_IS_BEING_REMOVED - The volume is being removed
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_READONLY_TO_READONLY_SNAP - Creating a read-only copy from a read-only volume is not permitted
    # * Hpe3parSdk::HTTPConflict
    #        - NO_SNAP_CPG - No snapshot CPG has been configured for the volume  
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_DUP_NAME - Invalid input (duplicate name).
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_SNAP_PARENT_SAME_BASE - Two parent snapshots share the same base volume
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_ONLINE_COPY_IN_PROGRESS - Invalid operation. Online copyis in progress
    # * Hpe3parSdk::HTTPServiceUnavailable
    #        - VV_ID_LIMIT_REACHED - Max number of volumeIDs has been reached
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_VOLUME - The volume does not exists
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_IN_STALE_STATE - The volume is in a stale state.
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_NOT_STARTED - Volume is not started
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_UNAVAILABLE - The volume is not accessible
    # * Hpe3parSdk::HTTPServiceUnavailable
    #        - SNAPSHOT_LIMIT_REACHED - Max number of snapshots has been reached
    # * Hpe3parSdk::HTTPServiceUnavailable
    #        - CPG_ALLOCATION_WARNING_REACHED - The CPG has reached the allocation warning
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_VOLUME_CONV_IN_PROGRESS - Invalid operation: VV conversion is in progress.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_CLEANUP_IN_PROGRESS - Internal volume cleanup is in progress.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_PEER_VOLUME - Cannot modify a peer volume.
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_VV_VOLUME_CONV_IN_PROGRESS - INV_OPERATION_VV_ONLINE_COPY_IN_PROGRESS  - The volume is the target of an online copy.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_INTERNAL_VOLUME - Illegal op on internal vol
    # * Hpe3parSdk::HTTPConflict
    #        - EXISTENT_ID - An ID exists
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_VV_NOT_IN_NORMAL_STATE - Volume state is not normal
    # * Hpe3parSdk::HTTPForbidden
    #        - VV_IN_INCONSISTENT_STATE - Internal inconsistency error in vol
    # * Hpe3parSdk::HTTPBadRequest
    #        - INVALID_INPUT_VV_PATTERN - - INV_INPUT_RETAIN_GT_EXPIRE - Retention time is greater than expiration time.
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT_TIME - Invalid time specified.
    # * Hpe3parSdk::HTTPForbidden
    #        - INV_OPERATION_SNAPSHOT_NOT_SAME_TYPE - Some snapshots in the volume set are read-only, some are read-write
    def create_snapshot_of_volume_set(name, copy_of_name, optional = nil)
      begin
        @volume_set.create_snapshot_of_volume_set(name, copy_of_name, optional)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Creates a snapshot of an existing Volume.
    #
    # ==== Attributes
    #
    # * name - the name of the Snapshot
    #      type name: String
    # * copy_of_name - the name of the parent volume
    #      type copy_of_name: String
    # * optional - Hash of other optional items
    #      type optional: Hash
    #
    #      optional = {
    #             'id' => 12,                   # Specifies the ID of the volume,
    #                                           # next by default
    #             'comment' => "some comment",  
    #             'readOnly' => true,           # Read Only
    #             'expirationHours' => 36,      # time from now to expire
    #             'retentionHours' => 12        # time from now to expire
    #      }
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPNotFound
    #        - INON_EXISTENT_VOL - The volume does not exist
    # * Hpe3parSdk::HTTPForbidden
    #        - PERM_DENIED - Permission denied
    def create_snapshot(name, copy_of_name, optional = nil)
      if @current_version < @min_version_with_compression && !optional.nil?
        optional.delete_if { |key, _value| key == :allowRemoteCopyParent }
      end
      begin
        @volume.create_snapshot(name, copy_of_name, optional)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Restores from a snapshot to a volume
    #
    # ==== Attributes
    #
    # * name - the name of the Snapshot
    #      type name: String
    # * optional - hash of other optional items
    #      type name: Hash
    #
    #      optional = {
    #             'online' => false,                # Enables (true) or disables
    #                                               #(false) executing the promote
    #                                               #operation on an online volume.
    #                                               #The default setting is false
    #
    #             'priority' => 2                   #Does not apply to online promote
    #                                               #operation or to stop promote
    #                                               #operation.
    #
    #             'allowRemoteCopyParent' => false  #Allows the promote operation to
    #                                               #proceed even if the RW parent
    #                                               #volume is currently in a Remote
    #                                               #Copy volume group, if that group
    #                                               #has not been started. If the
    #                                               #Remote Copy group has been
    #                                               #started, this command fails.
    #                                               #(WSAPI 1.6 and later.)
    #      }
    #
    def restore_snapshot(name, optional = nil)
      if @current_version < @min_version_with_compression && !optional.nil?
        optional.delete_if { |key, _value| key == :allowRemoteCopyParent }
      end
      begin
        @volume.restore_snapshot(name, optional)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Deletes a snapshot
    #
    # ==== Attributes
    #
    # * name - the name of the snapshot volume
    #      type name: String
    #
    # ==== Raises:
    #
    # * Hpe3parSdk::HTTPNotFound
    #        - NON_EXISTENT_VOL - The volume does not exist
    # * Hpe3parSdk::HTTPForbidden
    #        - PERM_DENIED - Permission denied
    # * Hpe3parSdk::HTTPForbidden
    #        - RETAINED - Volume retention time has not expired
    # * Hpe3parSdk::HTTPForbidden
    #        - HAS_RO_CHILD - Volume has read-only child
    # * Hpe3parSdk::HTTPConflict
    #        - HAS_CHILD - The volume has a child volume
    # * Hpe3parSdk::HTTPConflict
    #        - IN_USE - The volume is in use by VV set, VLUN, etc
    def delete_snapshot(name)
      begin
        @volume.delete_volume(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets the snapshots of a particular volume
    #
    # ==== Attributes
    #
    # * name - the name of the volume
    #      type name: String
    #
    # ==== Returns
    #
    # Array of VirtualVolume
    def get_volume_snapshots(name)
      begin
        @volume.get_volume_snapshots(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets an array of all ports on the 3PAR.
    #
    # ==== Returns
    #
    # Array of Port.
    def get_ports
      begin
        @port.get_ports
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets an array of Fibre Channel Ports.
    #
    # * state - Port link state.
    #      type name: Integer. Refer Hpe3parSdk::PortLinkState for complete enumeration.
    #
    # ==== Returns
    #
    # Array of Fibre Channel Port.
    def get_fc_ports(state = nil)
      begin
        @port.get_fc_ports(state)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets an array of iSCSI Ports.
    #
    # * state - Port link state.
    #      type name: Integer. Refer Hpe3parSdk::PortLinkState for complete enumeration.
    #
    # ==== Returns
    #
    # Array of iSCSI Port.
    def get_iscsi_ports(state = nil)
      begin
        @port.get_iscsi_ports(state)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets an array of IP Ports.
    #
    # ==== Attributes
    #
    # * state - Port link state.
    #      type name: Integer. Refer Hpe3parSdk::PortLinkState for complete enumeration.
    #
    # ==== Returns
    #
    # Array of IP Port.
    def get_ip_ports(state = nil)
      begin
        @port.get_ip_ports(state)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets entire list of CPGs.
    #
    # ==== Returns
    #
    # CPG array
    def get_cpgs
      begin
        @cpg.get_cpgs
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets information about a Cpg.
    #
    # ==== Attributes
    #
    # * name - The name of the cpg to find
    #      type name: String
    #
    # ==== Returns
    #
    # CPG 
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HPE3PARException
    #       Error with code: 15 message: cpg does not exist
    def get_cpg(name)
      begin
        @cpg.get_cpg(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end


    # Creates a new CPG.
    #
    # ==== Attributes
    #
    # * name - Name of the cpg
    #      type name: String
    # * optional - Hash of other optional items
    #      type optional: Hash
    #
    #      optional = {
    #            'growthIncrementMiB' 100,    # Growth increment in MiB for
    #                                          # each auto-grown operation
    #            'growthLimitMiB': 1024,       # Auto-grow operation is limited
    #                                          # to specified storage amount
    #            'usedLDWarningAlertMiB': 200, # Threshold to trigger warning
    #                                          # of used logical disk space
    #            'domain': 'MyDomain',         # Name of the domain object
    #            'LDLayout': {
    #                'RAIDType': 1,            # Disk Raid Type
    #                'setSize': 100,           # Size in number of chunklets
    #                'HA': 0,                  # Layout supports failure of
    #                                          # one port pair (1),
    #                                          # one cage (2),
    #                                          # or one magazine (3)
    #                'chunkletPosPref': 2,     # Chunklet location perference
    #                                          # characteristics.
    #                                          # Lowest Number/Fastest transfer
    #                                          # = 1
    #                                          # Higher Number/Slower transfer
    #                                          # = 2
    #                'diskPatterns': []}       # Patterns for candidate disks
    #    }
    #
    # ==== Raises
    # * Hpe3parSdk::HTTPBadRequest
    #        - INV_INPUT Invalid URI Syntax.
    # * Hpe3parSdk::HTTPBadRequest
    #        - NON_EXISTENT_DOMAIN - Domain doesn't exist.
    # * Hpe3parSdk::HTTPBadRequest
    #        - NO_SPACE - Not Enough space is available.
    # * Hpe3parSdk::HTTPBadRequest
    #        - BAD_CPG_PATTERN  A Pattern in a CPG specifies illegal values.
    # * Hpe3parSdk::HTTPForbidden
    #        - PERM_DENIED - Permission denied
    # * Hpe3parSdk::HTTPConflict
    #        - EXISTENT_CPG - Cpg Exists already
    def create_cpg(name, optional = nil)
      begin
        @cpg.create_cpg(name, optional)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Modifies a CPG.
    #
    # ==== Attributes
    #
    # * name - Name of the CPG
    #      type name: String
    # * optional - hash of other optional items
    #      type optional: Hash
    #
    #      optional = {
    #            'newName'=> "newCPG:,          # Specifies the name of the
    #                                           # CPG to update.
    #            'disableAutoGrow'=>false,      # Enables (false) or
    #                                           # disables (true) CPG auto
    #                                           # grow. Defaults to false.
    #            'rmGrowthLimit'=> false,       # Enables (false) or
    #                                           # disables (true) auto grow
    #                                           # limit enforcement. Defaults
    #                                           # to false.
    #            'rmWarningAlert'=> false,      # Enables (false) or
    #                                           # disables (true) warning
    #                                           # limit enforcement. Defaults
    #                                           # to false.
    #      }
    #
    def modify_cpg(name, cpg_mods)
      begin
        @cpg.modify_cpg(name, cpg_mods)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets available space information about a cpg.
    #
    # ==== Attributes
    #
    # * name - The name of the cpg to find
    #      type name: String
    #
    # ==== Returns
    #
    # Available space details in form of LDLayoutCapacity object
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HPE3PARException
    #       Error with code: 15 message: cpg does not exist
    def get_cpg_available_space(name)
      begin
        @cpg.get_cpg_available_space(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Deletes a CPG.
    #
    # ==== Attributes
    #
    # * name - The name of the CPG
    #      type name: String
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HPE3PARException
    #       Error with code: 15 message: CPG does not exist
    # * Hpe3parSdk::HTTPForbidden
    #        -  IN_USE - The CPG Cannot be removed because it's in use.
    # * Hpe3parSdk::HTTPForbidden
    #        - PERM_DENIED - Permission denied
    def delete_cpg(name)
      begin
        @cpg.delete_cpg(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Gets the status of an online physical copy
    #
    # ==== Attributes
    #
    # * name - The name of the volume
    #      type name: str
    #
    # ==== Returns
    #
    # Status of online copy (String)
    #
    # ==== Raises
    #
    # * Hpe3parSdk::HPE3PARException
    #       Error: message: Volume not an online physical copy
    def get_online_physical_copy_status(name)
      begin
        @volume.get_online_physical_copy_status(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Stops an offline physical copy operation
    #
    # ==== Attributes
    #
    # * name - The name of the volume
    #      type name: String
    def stop_offline_physical_copy(name)
      begin
        @volume.stop_offline_physical_copy(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Stops an online physical copy operation
    #
    # ==== Attributes
    #
    # * name - The name of the volume
    #      type name: String
    def stop_online_physical_copy(name)
      begin
        @volume.stop_online_physical_copy(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Resynchronizes a physical copy.
    #
    # ==== Attributes
    #
    # * name - The name of the volume
    #      type name: String
    def resync_physical_copy(name)
      begin
        @volume.resync_physical_copy(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Waits for a 3PAR task to end.
    #
    # ==== Attributes
    #
    # * task_id - The Id of the task to be waited upon.
    #      type task_id: Integer
    # * poll_rate_secs - The polling interval in seconds.
    #      type poll_rate_secs: Integer
    def wait_for_task_to_end(task_id, poll_rate_secs = 15)
      begin
        @task.wait_for_task_to_end(task_id, poll_rate_secs)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Cancel a 3PAR task
    #
    # ==== Attributes
    #
    # * task_id - The Id of the task to be cancelled.
    #      type task_id: Integer
    # ==== Raises
    #
    # * Hpe3parSdk::HTTPBadRequest
    #        - NON_ACTIVE_TASK - The task is not active at this time.
    # * Hpe3parSdk::HTTPConflict
    #        - INV_OPERATION_CANNOT_CANCEL_ TASK - Invalid operation: Task cannot be cancelled.
    def cancel_task(task_id)
      begin
        @task.cancel_task(task_id)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end
   
    def flash_cache_exists?
      begin
        @flash_cache.flash_cache_exists?
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end  

    def volume_exists?(name)
      begin
        @volume.volume_exists?(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    def volume_set_exists?(name)
      begin
        @volume_set.volume_set_exists?(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end
    
    def host_exists?(host_name)
      begin
        @host.host_exists?(host_name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    def host_set_exists?(host_name)
      begin
        @host_set.host_set_exists?(host_name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    def cpg_exists?(name)
      begin
        @cpg.cpg_exists?(name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    def flash_cache_exists?
      begin
        @flash_cache.flash_cache_exists?
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end  

    def online_physical_copy_exists?(src_name, phy_copy_name)
      begin
        @volume.online_physical_copy_exists?(src_name, phy_copy_name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    def offline_physical_copy_exists?(src_name, phy_copy_name)
      begin
        @volume.offline_physical_copy_exists?(src_name, phy_copy_name)
      rescue => ex
        Util.log_exception(ex, caller_locations(1, 1)[0].label)
        raise ex
      end
    end

    # Logout from the 3PAR Array
    def logout
      unless @log_file_path.nil?
        if Hpe3parSdk.logger != nil
          Hpe3parSdk.logger.close
          Hpe3parSdk.logger = nil
        end
      end
      begin
        @http.unauthenticate
      rescue Hpe3parSdk::HPE3PARException => ex
        #Do nothing
      end
    end
  end
end
