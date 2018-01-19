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
  class WSAPIVersionSupport
    WSAPI_MIN_SUPPORTED_VERSION = '1.5.0'.freeze
    WSAPI_MIN_VERSION_VLUN_QUERY_SUPPORT = '1.4.2'.freeze
    WSAPI_MIN_VERSION_COMPRESSION_SUPPORT = '1.6.0'.freeze

  end

  ##
  # This class enumerates the RAID types supported by HPE 3PAR.
  class CPGRAIDType
    R0 = 1
    R1 = 2
    R5 = 3
    R6 = 4
  end

  ##
  # This class enumerates the High Availability settings for a CPG.
  class CPGHA
    PORT = 1
    CAGE = 2
    MAG = 3
  end

  class RaidTypeSetSizeMap
    R0 = [1]
    R1 = [2, 3, 4]
    R5 = [3, 4, 5, 6, 7, 8, 9]
    R6 = [6, 8, 10, 12, 16]
  end

  ##
  # This class enumerates the Chunklet position preference for a CPG.
  class CPGChunkletPosPref
    FIRST = 1
    LAST = 2
  end

  ##
  # This class enumerates the Detailed state values for a CPG.
  class CPGDetailedState
    SA_LIMIT_REACHED = 1
    SD_LIMIT_REACHED = 2
    SA_GROW_FAILED = 3
    SD_GROW_FAILED = 4
    SA_WARN_REACHED = 5
    SD_WARN_REACHED = 6
    INVALID = 7
  end

  ##
  # This class enumerates the Disk type values for a CPG.
  class CPGDiskType
    FC = 1
    NL = 2
    SSD = 3
  end

  ##
  # This class enumerates the State values for a CPG.
  class CPGState
    NORMAL = 1
    DEGRADED = 2
    FAILED = 3
    UNKNOWN = 99
  end

  ##
  # This class enumerates the Compression state values for a Volume.
  class VolumeCompressionState
    YES = 1
    NO = 2
    OFF = 3
    NA = 4
  end

  ##
  # This class enumerates the Provisioning type values for a Volume.
  class VolumeProvisioningType
    FULL = 1
    TPVV = 2
    SNP = 3
    PEER = 4
    UNKNOWN = 5
    TDVV = 6
    DDS = 7
  end

  ##
  # This class enumerates the Copy type values for a Volume.
  class VolumeCopyType
    BASE_VOLUME = 1
    PHYSICAL_COPY = 2
    VIRTUAL_COPY = 3
  end

  ##
  # This class enumerates the De-duplication state values for a Volume.
  class VolumeDeduplicationState
    YES = 1
    NO = 2
    NA = 3
  end

  ##
  # This class enumerates the Detailed state values for a Volume.
  class VolumeDetailedState
    LDS_NOT_STARTED = 1
    NOT_STARTED = 2
    NEEDS_CHECK = 3
    NEEDS_MAINT_CHECK = 4
    INTERNAL_CONSISTENCY_ERROR = 5
    SNAPDATA_INVALID = 6
    PRESERVED = 7
    STALE = 8
    COPY_FAILED = 9
    DEGRADED_AVAIL = 10
    DEGRADED_PERF = 11
    PROMOTING = 12
    COPY_TARGET = 13
    RESYNC_TARGET = 14
    TUNING = 15
    CLOSING = 16
    REMOVING = 17
    REMOVING_RETRY = 18
    CREATING = 19
    COPY_SOURCE = 20
    IMPORTING = 21
    CONVERTING = 22
    INVALID = 23
  end

  ##
  # This class enumerates the Host DIF values for a Volume.
  class VolumeHostDIF
    PAR_HOST_DIF = 1
    STD_HOST_DIF = 2
    NO_HOST_DIF = 3
  end

  ##
  # This class enumerates the Custom actions that can be applied on a Volume.
  class VolumeCustomAction
    STOP_PHYSICAL_COPY = 1
    RESYNC_PHYSICAL_COPY = 2
    GROW_VOLUME = 3
    PROMOTE_VIRTUAL_COPY = 4
    STOP_PROMOTE_VIRTUAL_COPY = 5
    TUNE_VOLUME = 6
    UPDATE_VIRTUAL_COPY = 7
    SNAPSHOT_ENUM_ACTION = 8
  end

  ##
  # This class enumerates the Tune operations that can be applied on a Volume.
  class VolumeTuneOperation
    USR_CPG = 1
    SNP_CPG = 2
  end

  ##
  # This class enumerates the types of a VLUN.
  class VlunType
    EMPTY = 1
    PORT = 2
    HOST = 3
    MATCHED_SET = 4
    HOST_SET = 5
  end

  ##
  # This class enumerates the types of multi-pathing for a VLUN.
  class VlunMultipathing
    UNKNOWN = 1
    ROUND_ROBIN = 2
    FAILOVER = 3
  end

  ##
  # This class enumerates the types of failed path policies.
  class VLUNfailedPathPol
    UNKNOWN = 1
    SCSI_TEST_UNIT_READY = 2
    INQUIRY = 3
    READ_SECTOR0 = 4
  end

  ##
  # This class enumerates the type of a Volume.
  class VolumeConversionOperation
    TPVV = 1
    FPVV = 2
    TDVV = 3
  end

  ##
  # This class enumerates the types QOS targets.
  class QoStargetTypeConstants
    VVSET = 'vvset'.freeze
    SYS = 'sys'.freeze
  end

  ##
  # This class enumerates the various QOS target types.
  class QoStargetType
    VVSET = 1
    SYS = 2
  end

  ##
  # This class enumerates the various QOS priorities.
  class QoSpriorityEnumeration
    LOW = 1
    NORMAL = 2
    HIGH = 3
  end

  ##
  # This class enumerates options which can be used
  # for QoS rule creation or modification.
  # Refer HPE 3PAR WSAPI 1.6 documentation
  class QosZeroNoneOperation
    ZERO = 1
    NOLIMIT = 2
  end


  ##
  # This class enumerates options which can be used
  # for Flash Cache creation or modification.
  # Refer HPE 3PAR WSAPI 1.6 documentation
  class FlashCachePolicy
    ENABLE = 1
    DISABLE = 2
  end

  ##
  # This class enumerates custom actions which can be used
  # on a VVSet.
  # Refer HPE 3PAR WSAPI 1.6 documentation
  class SetCustomAction
    MEM_ADD = 1
    MEM_REMOVE = 2
    RESYNC_PHYSICAL_COPY = 3
    STOP_PHYSICAL_COPY = 4
    PROMOTE_VIRTUAL_COPY = 5
    STOP_PROMOTE_VIRTUAL_COPY = 6
  end

  ##
  # This class enumerates the various types of a Task.
  class TaskType
    VV_COPY = 1
    PHYS_COPY_RESYNC = 2
    MOVE_REGIONS = 3
    PROMOTE_SV = 4
    REMOTE_COPY_SYNC = 5
    REMOTE_COPY_REVERSE = 6
    REMOTE_COPY_FAILOVER = 7
    REMOTE_COPY_RECOVER = 8
    REMOTE_COPY_RESTORE = 9
    COMPACT_CPG = 10
    COMPACT_IDS = 11
    SNAPSHOT_ACCOUNTING = 12
    CHECK_VV = 13
    SCHEDULED_TASK = 14
    SYSTEM_TASK = 15
    BACKGROUND_TASK = 16
    IMPORT_VV = 17
    ONLINE_COPY = 18
    CONVERT_VV = 19
    BACKGROUND_COMMAND = 20
  end

  ##
  # This class enumerates the priorities that a Task can have.
  class TaskPriority
    HIGH = 1
    MEDIUM = 2
    LOW = 3
  end

  ##
  # This class enumerates the statuses that a Task can have.
  class TaskStatus
    DONE = 1
    ACTIVE = 2
    CANCELLED = 3
    FAILED = 4


    def self.get_string(val)
      case val
        when 1
          return 'DONE'
        when 2
          return 'ACTIVE'
        when 3
          return 'CANCELLED'
        when 4
          return 'FAILED'
        else
          raise 'Unknown value'
      end

    end
  end

  ##
  # This class enumerates the modes of a Port.
  class PortMode
    SUSPENDED = 1
    TARGET = 2
    INITIATOR = 3
    PEER = 4
  end

  ##
  # This class enumerates the link states of a Port.
  class PortLinkState
    CONFIG_WAIT = 1
    ALPA_WAIT = 2
    LOGIN_WAIT = 3
    READY = 4
    LOSS_SYNC = 5
    ERROR_STATE = 6
    XXX = 7
    NONPARTICIPATE = 8
    COREDUMP = 9
    OFFLINE = 10
    FWDEAD = 11
    IDLE_FOR_RESET = 12
    DHCP_IN_PROGRESS = 13
    PENDING_RESET = 14
  end

  ##
  # This class enumerates the connection types of a Port.
  class PortConnType
    HOST = 1
    DISK = 2
    FREE = 3
    IPORT = 4
    RCFC = 5
    PEER = 6
    RCIP = 7
    ISCSI = 8
    CNA = 9
    FS = 10
  end

  ##
  # This class enumerates the protocols that a Port can support.
  class PortProtocol
    FC = 1
    ISCSI = 2
    FCOE = 3
    IP = 4
    SAS = 5
  end

  ##
  # This class enumerates the various fail over states of a Port.
  class PortFailOverState
    NONE = 1
    FAILOVER_PENDING = 2
    FAILED_OVER = 3
    ACTIVE = 4
    ACTIVE_DOWN = 5
    ACTIVE_FAILED = 6
    FAILBACK_PENDING = 7
  end

  ##
  # This class enumerates the various personae that a Host can have.
  class HostPersona
    GENERIC = 1
    GENERIC_ALUA = 2
    GENERIC_LEGACY = 3
    HPUX_LEGACY = 4
    AIX_LEGACY = 5
    EGENERA = 6
    ONTAP_LEGACY = 7
    VMWARE = 8
    OPENVMS = 9
    HPUX = 10
    WINDOWS_SERVER = 11
  end

  ##
  # This class enumerates the various Chap operation modes.
  class ChapOperationMode
    INITIATOR = 1
    TARGET = 2
  end

  ##
  # This class enumerates the various operations related to editing a Host.
  class HostEditOperation
    ADD = 1
    REMOVE = 2
  end

  ##
  # This class enumerates the various actions that can be applied on a Task.
  class TaskAction
    CANCEL_TASK = 1
  end
end
