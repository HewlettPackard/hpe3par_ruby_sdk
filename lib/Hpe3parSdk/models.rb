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
  class VirtualVolume

    # [type - Number]
    # Detailed state of the VV - Hpe3parSdk::VolumeDetailedState
    attr_accessor :additional_states

    # [type - Space]
    # Administrative space in MiB.
    attr_accessor :admin_space

    # [type - Number]
    # The ID of the volume that is the base
    # volume (at the root of the snapshot
    # tree) for the volume.
    attr_accessor :base_id

    # [type - String]
    # Comment associated with the volume.
    attr_accessor :comment

    # [type - CapEfficiency]
    # Capacity efficiency attributes.
    attr_accessor :capacity_efficiency

    # [type - String]
    # If the volume is a physical copy or
    # virtual copy of another volume, this
    # field indicates the volume that this
    # volume is a copy of.
    attr_accessor :copy_of

    # [type - Number]
    # Indicates the copy type of the volume. - Hpe3parSdk::VolumeCopyType
    attr_accessor :copy_type

    # [type - String]
    # Time of volume creation.
    attr_accessor :creation_time8601

    # [type - Number]
    # Time of volume creation, measured in
    # seconds since 12 AM on 01/01/1970.
    attr_accessor :creation_time_sec

    # [type - Number]
    # Volume detailed state. - Hpe3parSdk::VolumeDetailedState
    attr_accessor :degraded_states

    # [type - String]
    # Volume domain.
    attr_accessor :domain

    # [type - String]
    # Time of volume expiration.
    attr_accessor :expiration_time8601

    # [type - Number]
    # Time of volume expiration.
    attr_accessor :expiration_time_sec

    # [type - Number]
    # Volume detailed state. - Hpe3parSdk::VolumeDetailedState
    attr_accessor :failed_states

    # [type - Number]
    # Volume compression state - Hpe3parSdk::VolumeCompressionState
    attr_accessor :compression_state

    # [type - Number]
    # Volume deduplication state. - Hpe3parSdk::VolumeDetailedState
    attr_accessor :deduplication_state

    # [type - Number]
    # Volume identifier.
    attr_accessor :id

    # [type - Array of URL links]
    # Links include the URL for space
    # distribution for a particular volume, and
    # the self URL when querying for the
    # single instance.
    attr_accessor :links

    # [type - String]
    # Volume name.
    attr_accessor :name

    # [type - Number]
    # ID of the parent in the snapshot tree
    # (not necessarily the same as the
    # CopyOf VV).
    attr_accessor :parent_id

    # [type - Number]
    # ID of the physical parent. Valid for a
    # physical copy only.
    attr_accessor :phys_parent_id

    # [type - Policy]
    # Policies used for the volume.
    attr_accessor :policies

    # [type - Number]
    # Volume provisioning. - Hpe3parSdk::VolumeProvisioningType
    attr_accessor :provisioning_type

    # [type - Boolean]
    # Enables (true) or disables (false)
    # read/write.
    attr_accessor :read_only

    # [type - String]
    # Time of volume retention time
    # expiration.
    attr_accessor :retention_time8601

    # [type - Number]
    # Time of volume retention expiration.
    attr_accessor :retention_time_sec

    # [type - Number]
    # ID of the read-only child volume in the
    # snapshot tree.
    attr_accessor :ro_child_id

    # [type - Number]
    # ID of the read/write child volume in the
    # snapshot tree.
    attr_accessor :rw_child_id

    # [type - Number]
    # Total written to volume. For TDVVs this
    # includes shared data that this volume
    # references.
    attr_accessor :host_write_mib

    # [type - Number]
    # Total used space. Sum of used
    # UserSpace and used Snapshot space.
    attr_accessor :total_used_mib

    # [type - Number]
    # Total Reserved space.
    attr_accessor :total_reserved_mib

    # [type - Number]
    # Detailed Virtual size of volume in MiB (10242
    # bytes).
    attr_accessor :size_mib

    # [type - String]
    # CPG name from which the snapshot
    # (snap and admin) space is allocated.
    attr_accessor :snap_cpg

    # [type - Space]
    # Snapshot space in MiB.
    attr_accessor :snapshot_space

    # [type - Number]
    # Sets a snapshot space allocation limit.
    # Prevents the snapshot space of the
    # volume from growing beyond the
    # indicated percentage of the volume
    # size.
    attr_accessor :ss_spc_alloc_limit_pct

    # [type - Number]
    # Enables a snapshot space allocation
    # warning. Generates a warning alert
    # when the reserved snapshot space of
    # the virtual volume exceeds the
    # indicated percentage of the virtual
    # volume size. - Hpe3parSdk::VolumeDetailedState
    attr_accessor :ss_spc_alloc_warning_pct

    # [type - Number]
    # State of the volume. - Hpe3parSdk::CPGState
    attr_accessor :state

    # [type - String]
    # CPG name from which the user space
    # is allocated.
    attr_accessor :user_cpg

    # [type - Space]
    # User space in MiB.
    attr_accessor :user_space

    # [type - Number]
    # This field sets the user space allocation
    # limit. The user space of the TPVV is
    # prevented from growing beyond the
    # specified percentage of the volume
    # size. After the size is reached, any new
    # writes to the volume will fail.
    attr_accessor :usr_spc_alloc_limit_pct

    # [type - Number]
    # This field enables a user space
    # allocation warning. It specifies that a
    # warning alert is generated when the
    # reserved user space of the TPVV
    # exceeds the specified percentage of
    # the volume size.
    attr_accessor :usr_spc_alloc_warning_pct

    # [type - String]
    # The UUID that was automatically
    # assigned to the volume at creation.
    attr_accessor :uuid

    # [type - Number]
    # The ID of the shared volume that this
    # volume is associated with.
    attr_accessor :shared_parent_id

    # [type - Number]
    # User-Defined identifier per VV for
    # OpenVMS hosts.
    attr_accessor :udid

    # [type - String]
    # Volume WWN.
    attr_accessor :wwn

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.additional_states = object_hash['additionalStates']

      !object_hash['adminSpace'].nil? ? self.admin_space = Space.new(object_hash['adminSpace']) : self.admin_space = nil

      self.base_id = object_hash['baseId']

      self.comment = object_hash['comment']

      !object_hash['capacityEfficiency'].nil? ? self.capacity_efficiency = CapEfficiency.new(object_hash['capacityEfficiency']) : self.capacity_efficiency = nil

      self.copy_of = object_hash['copyOf']

      self.copy_type = object_hash['copyType']

      self.creation_time8601 = object_hash['creationTime8601']

      self.creation_time_sec = object_hash['creationTimeSec']

      self.degraded_states = object_hash['degradedStates']

      self.domain = object_hash['domain']

      self.expiration_time8601 = object_hash['expirationTime8601']

      self.expiration_time_sec = object_hash['expirationTimeSec']

      self.failed_states = object_hash['failedStates']

      self.compression_state = object_hash['compressionState']

      self.deduplication_state = object_hash['deduplicationState']

      self.id = object_hash['id']

      self.links = object_hash['links']

      self.name = object_hash['name']

      self.parent_id = object_hash['parentId']

      self.phys_parent_id = object_hash['physParentId']

      !object_hash['policies'].nil? ? self.policies = Policy.new(object_hash['policies']) : self.policies = nil

      self.provisioning_type = object_hash['provisioningType']

      self.read_only = object_hash['readOnly']

      self.retention_time8601 = object_hash['retentionTime8601']

      self.retention_time_sec = object_hash['retentionTimeSec']

      self.ro_child_id = object_hash['roChildId']

      self.rw_child_id = object_hash['rwChildId']

      self.host_write_mib = object_hash['hostWriteMiB']

      self.total_used_mib = object_hash['totalUsedMiB']

      self.total_reserved_mib = object_hash['totalReservedMiB']

      self.size_mib = object_hash['sizeMiB']

      self.snap_cpg = object_hash['snapCPG']

      !object_hash['snapshotSpace'].nil? ? self.snapshot_space = Space.new(object_hash['snapshotSpace']) : self.snapshot_space = nil

      self.ss_spc_alloc_limit_pct = object_hash['ssSpcAllocLimitPct']

      self.ss_spc_alloc_warning_pct = object_hash['ssSpcAllocWarningPct']

      self.state = object_hash['state']

      self.user_cpg = object_hash['userCPG']

      !object_hash['userSpace'].nil? ? self.user_space = Space.new(object_hash['userSpace']) : self.user_space = nil

      self.usr_spc_alloc_limit_pct = object_hash['usrSpcAllocLimitPct']

      self.usr_spc_alloc_warning_pct = object_hash['usrSpcAllocWarningPct']

      self.uuid = object_hash['uuid']

      self.shared_parent_id = object_hash['sharedParentID']

      self.udid = object_hash['udid']

      self.wwn = object_hash['wwn']
    end
  end

  class Host

    # [type - Number]
    # Specifies the ID of the host.
    attr_accessor :id

    # [type - String]
    # Specifies the name of the host.
    attr_accessor :name

    # [type - Hpe3parSdk::HostPersona]
    # ID of the persona to assigned to the host.
    attr_accessor :persona

    # [type - Array of FCPath]
    # A host object query response can include an array of one or more FCPaths objects
    attr_accessor :fcpaths

    # [type - Array of SCSIPath]
    # A host object query response can include an array of one or more iSCSIPaths objects.
    attr_accessor :iscsi_paths

    # [type - String]
    # The domain or associated with this host.
    attr_accessor :domain

    # [type - Descriptors]
    # An optional sub-object of the host object for creation and modification
    attr_accessor :descriptors

    # [type - Agent]
    # Agent object
    attr_accessor :agent

    # [type - String]
    # Initiator Chap Name
    attr_accessor :initiator_chap_name

    # [type - Boolean]
    # Flag to determine whether or not the chap initiator is enabled.
    attr_accessor :initiator_chap_enabled

    # [type - String]
    # Target chap name.
    attr_accessor :target_chap_name

    # [type - Boolean]
    # Flag to determine whether or not the chap target is enabled.
    attr_accessor :target_chap_enabled

    # [type - String]
    # Encrypted CHAP secret of initiator.
    attr_accessor :initiator_encrypted_chap_secret

    # [type - String]
    # Encrypted CHAP secret of target.
    attr_accessor :target_encrypted_chap_secret

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.id = object_hash['id']

      self.name = object_hash['name']

      self.persona = object_hash['persona']

      self.fcpaths = []
      unless object_hash['FCPaths'].nil?
        object_hash['FCPaths'].each do |fc_path|
          self.fcpaths.push(FCPath.new(fc_path))
        end
      end

      self.iscsi_paths = []
      unless object_hash['iSCSIPaths'].nil?
        object_hash['iSCSIPaths'].each do |iscsi_path|
          self.iscsi_paths.push(SCSIPath.new(iscsi_path))
        end
      end

      self.domain = object_hash['domain']

      !object_hash['descriptors'].nil? ? self.descriptors = Descriptors.new(object_hash['descriptors']) : self.descriptors = nil

      !object_hash['agent'].nil? ? self.agent = Agent.new(object_hash['agent']) : self.agent = nil

      self.initiator_chap_name = object_hash['initiatorChapName']

      self.initiator_chap_enabled = object_hash['initiatorChapEnabled']

      self.target_chap_name = object_hash['targetChapName']

      self.target_chap_enabled = object_hash['targetChapEnabled']

      self.initiator_encrypted_chap_secret = object_hash['initiatorEncryptedChapSecret']

      self.target_encrypted_chap_secret = object_hash['targetEncryptedChapSecret']

    end
  end

  class QoSRule

    # [type - Number]
    # ID of the QoS target.
    attr_accessor :id

    # [type - Hpe3parSdk::QoStargetType]
    # Type of QoS target.
    attr_accessor :type

    # [type - String]
    # Name of the target
    attr_accessor :name

    # [type - String]
    # Name of the domain.
    attr_accessor :domain

    # [type - Boolean]
    # QoS state of the target.
    attr_accessor :enabled

    # [type - Hpe3parSdk::QoSpriorityEnumeration]
    # QoS priority.
    attr_accessor :priority

    # [type - Number]
    # Bandwidth minimum goal in kilobytes per second.
    attr_accessor :bw_min_goal_kb

    # [type - Number]
    # Bandwidth maximum limit in kilobytes per second.
    attr_accessor :bw_max_limit_kb

    # [type - Number]
    # I/O-per-second minimum goal.
    attr_accessor :io_min_goal

    # [type - Number]
    # I/O-per-second maximum limit.
    attr_accessor :io_max_limit

    # [type - Number]
    # Latency goal in milliseconds.
    attr_accessor :latency_goal

    # [type - Number]
    # Latency goal in microseconds.
    attr_accessor :latency_goal_usecs

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.id = object_hash['id']

      self.type = object_hash['type']

      self.name = object_hash['name']

      self.domain = object_hash['domain']

      self.enabled = object_hash['enabled']

      self.priority = object_hash['priority']

      self.bw_min_goal_kb = object_hash['bwMinGoalKB']

      self.bw_max_limit_kb = object_hash['bwMaxLimitKB']

      self.io_min_goal = object_hash['ioMinGoal']

      self.io_max_limit = object_hash['ioMaxLimit']

      self.latency_goal = object_hash['latencyGoal']

      self.latency_goal_usecs = object_hash['latencyGoaluSecs']

    end
  end

  class VLUN

    # [type - Number]
    # Exported LUN value.
    attr_accessor :lun

    # [type - String]
    # Name of exported virtual volume name or VV-set name.
    attr_accessor :volume_name

    # [type - String]
    # Host name or host set name to which the VLUN is exported.
    attr_accessor :hostname

    # [type - String]
    # Host WWN, or iSCSI name, or SAS address; depends on port type.
    attr_accessor :remote_name

    # [type - PortPos]
    # System port of VLUN exported to. It includes node number, slot number, and cardPort number.
    attr_accessor :port_pos

    # [type - Hpe3parSdk::VlunType]
    # VLUN type.
    attr_accessor :type

    # [type - String]
    # WWN of exported volume. If a VV set is exported, this value is null.
    attr_accessor :volume_wwn

    # [type - Hpe3parSdk::VlunMultipathing]
    # Multipathing method in use.
    attr_accessor :multipathing

    # [type - Hpe3parSdk::VLUNfailedPathPol]
    # Failed path monitoring method.
    attr_accessor :failed_path_pol

    # [type - Number]
    # Monitoring interval in seconds after which the host checks for failed paths.
    attr_accessor :failed_path_interval

    # [type - String]
    # The device name for this VLUN on the host.
    attr_accessor :host_device_name

    # [type - Boolean]
    # Specified if the VLUN is an active VLUN or a VLUN template.
    attr_accessor :active

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.lun = object_hash['lun']

      self.volume_name = object_hash['volumeName']

      self.hostname = object_hash['hostname']

      self.remote_name = object_hash['remoteName']

      !object_hash['portPos'].nil? ? self.port_pos = PortPos.new(object_hash['portPos']) : self.port_pos = nil

      self.type = object_hash['type']

      self.volume_wwn = object_hash['volumeWWN']

      self.multipathing = object_hash['multipathing']

      self.failed_path_pol = object_hash['failedPathPol']

      self.failed_path_interval = object_hash['failedPathInterval']

      self.host_device_name = object_hash['hostDeviceName']

      self.active = object_hash['active']

    end
  end

  class CPG

    # [type - Number]
    # Cpg ID.
    attr_accessor :id

    # [type - String]
    # The UUID that was automatically assigned to the Cpg at creation.
    attr_accessor :uuid

    # [type - String]
    # Cpg name.
    attr_accessor :name

    # [type - String]
    # Domain to which the Cpg belongs.
    attr_accessor :domain

    # [type - Number]
    # Percentage usage at which to issue an alert.
    attr_accessor :warning_pct

    # [type - Number]
    # Number of TPVVs allocated in the Cpg.
    attr_accessor :num_tpvvs

    # [type - Number]
    # Number of FPVVs allocated in the Cpg.
    attr_accessor :num_fpvvs

    # [type - Number]
    # Number of TDVVs created in the Cpg.
    attr_accessor :num_tdvvs

    # [type - Usage]
    # User data space usage.
    attr_accessor :usr_usage

    # [type - Usage]
    # Snap-shot administration usage.
    attr_accessor :sausage

    # [type - Usage]
    # Snap-shot data space usage.
    attr_accessor :sdusage

    # [type - GrowthParams]
    # Snap-shot administration space autogrowth parameters.
    attr_accessor :sagrowth

    # [type - GrowthParams]
    # Snap-shot data space auto-growth parameters.
    attr_accessor :sdgrowth

    # [type - Number]
    # Overall state of the Cpg.- Hpe3parSdk::CPGState
    attr_accessor :state

    # [type - Number]
    # Detailed state of the Cpg. - Hpe3parSdk::CPGState
    attr_accessor :failed_states

    # [type - Number]
    # Detailed state of the Cpg. - Hpe3parSdk::CPGState
    attr_accessor :degraded_states

    # [type - Number]
    # Detailed state of the Cpg. - Hpe3parSdk::CPGState
    attr_accessor :additional_states

    # [type - Boolean]
    # Enables (true) or disables (false) Cpg deduplication capability.
    attr_accessor :dedup_capable

    # [type - Number]
    # Shared Cpg space in MiB
    attr_accessor :shared_space_MiB

    # [type - Number]
    # Free Cpg space in MiB
    attr_accessor :free_space_MiB

    # [type - Number]
    # Total Cpg space in MiB
    attr_accessor :total_space_MiB

    # [type - Number]
    # Raw shared space in MiB
    attr_accessor :raw_shared_space_MiB

    # [type - Number]
    # Raw free space in MiB
    attr_accessor :raw_free_space_MiB

    # [type - Number]
    # Raw total space in MiB
    attr_accessor :raw_total_space_MiB

    # [type - Number]
    # Deduplication version used by volumes in the Cpg.
    attr_accessor :tdvv_version

    # [type - Number]
    # Maximum size of the deduplication store Volume in the Cpg.
    attr_accessor :dds_rsvd_MiB

    # [type - PrivateSpace]
    # Private Cpg space in MiB
    attr_accessor :private_space_MiB

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.id = object_hash['id']

      self.uuid = object_hash['uuid']

      self.name = object_hash['name']

      self.domain = object_hash['domain']

      self.warning_pct = object_hash['warningPct']

      self.num_tpvvs = object_hash['numTPVVs']

      self.num_fpvvs = object_hash['numFPVVs']

      self.num_tdvvs = object_hash['numTDVVs']

      !object_hash['UsrUsage'].nil? ? self.usr_usage = Usage.new(object_hash['UsrUsage']) : self.usr_usage = nil

      !object_hash['SAUsage'].nil? ? self.sausage = Usage.new(object_hash['SAUsage']) : self.sausage = nil

      !object_hash['SDUsage'].nil? ? self.sdusage = Usage.new(object_hash['SDUsage']) : self.sdusage = nil

      !object_hash['SAGrowth'].nil? ? self.sagrowth = GrowthParams.new(object_hash['SAGrowth']) : self.sagrowth = nil

      !object_hash['SDGrowth'].nil? ? self.sdgrowth = GrowthParams.new(object_hash['SDGrowth']) : self.sdgrowth = nil

      self.state = object_hash['state']

      self.failed_states = object_hash['failedStates']

      self.degraded_states = object_hash['degradedStates']

      self.additional_states = object_hash['additionalStates']

      self.dedup_capable = object_hash['dedupCapable']

      self.shared_space_MiB = object_hash['sharedSpaceMiB']

      self.free_space_MiB = object_hash['freeSpaceMiB']

      self.total_space_MiB = object_hash['totalSpaceMiB']

      self.raw_shared_space_MiB = object_hash['rawSharedSpaceMiB']

      self.raw_free_space_MiB = object_hash['rawFreeSpaceMiB']

      self.raw_total_space_MiB = object_hash['rawTotalSpaceMiB']

      self.tdvv_version = object_hash['tdvvVersion']

      self.dds_rsvd_MiB = object_hash['ddsRsvdMiB']

      !object_hash['privateSpaceMiB'].nil? ? self.private_space_MiB = PrivateSpace.new(object_hash['privateSpaceMiB']) : self.private_space_MiB = nil

    end
  end

  class FlashCache

    # [type - Number 1: Simulator 2: Real]
    # Encrypted CHAP secret of target.
    attr_accessor :mode

    # [type - Number]
    # The total size of the Flash Cache on the entire system. This might differ from the sizeGib input in the create Flash Cache request if the system has more than two nodes.
    attr_accessor :size_gib

    # [type - Hpe3parSdk::CPGState]
    # State of flash cache
    attr_accessor :state

    # [type - Number]
    # The used size of the Flash Cache.
    attr_accessor :used_size_gib

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.mode = object_hash['mode']

      self.size_gib = object_hash['sizeGiB']

      self.state = object_hash['state']

      self.used_size_gib = object_hash['usedSizeGiB']
    end
  end

  class HostSet

    # [type - String]
    # Name of the set.
    attr_accessor :name

    # [type - String]
    # UUID of the set.
    attr_accessor :uuid

    # [type - Number]
    # Set identifier.
    attr_accessor :id

    # [type - String]
    # Comment for the set.
    attr_accessor :comment

    # [type - String]
    # Set domain.
    attr_accessor :domain

    # [type - Array of String]
    # The members of the set.
    attr_accessor :setmembers

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.name = object_hash['name']

      self.uuid = object_hash['uuid']

      self.id = object_hash['id']

      self.comment = object_hash['comment']

      self.domain = object_hash['domain']

      self.setmembers = object_hash['setmembers']

    end
  end

  class Port

    # [type - PortPos]
    # port n:s:p.
    attr_accessor :port_pos

    # [type - Hpe3parSdk::PortMode]
    # port mode.
    attr_accessor :mode

    # [type - Hpe3parSdk::PortLinkState]
    # port link state.
    attr_accessor :linkState

    # [type - String]
    # Node WWN that is unique across all ports.
    attr_accessor :nodewwn

    # [type - String]
    # port WWN for FCoE and FC ports. Not included in JSON for other ports.
    attr_accessor :portwwn

    # [type - Hpe3parSdk::PortConnType]
    # port connection type.
    attr_accessor :type

    # [type - String]
    # Hardware address for RCIP and iSCSI ports. Not included in JSON for other ports.
    attr_accessor :hwaddr

    # [type - Hpe3parSdk::PortProtocol]
    # Indicates the port protocol type.
    attr_accessor :protocol

    # [type - String]
    # Configurable, human-readable label identifying the HBA port. Maximum length is 15 characters.
    attr_accessor :label

    # [type - Arry of string]
    # Array of device name (cage0, host1, etc.) of the device connected to the port.
    attr_accessor :device

    # [type - PortPos]
    # Location of failover partner port in <Node><Slot><Port> format.
    attr_accessor :partner_pos

    # [type - Hpe3parSdk::PortFailOverState]
    # The state of the failover operation, shown for the two ports indicated in the N:S:P and Partner columns.
    attr_accessor :failover_state

    # [type - String]
    # For RCIP and iSCSI ports only; not included in the JSON object for other ports.
    attr_accessor :ip_addr

    # [type - String]
    # For iSCSI port only; not included in the JSON object for other ports.
    attr_accessor :iscsi_name

    # [type - String]
    # Ethernet node MAC address.
    attr_accessor :enode_macaddr

    # [type - String]
    # PFC mask.
    attr_accessor :pfcmask

    # [type - ISCSIPortInfo]
    # Contains information related to iSCSI port properties.
    attr_accessor :iscsi_portinfo

    def initialize(object_hash)
      if object_hash == nil
        return
      end
      !object_hash['portPos'].nil? ? self.port_pos = PortPos.new(object_hash['portPos']) : self.port_pos = nil

      self.mode = object_hash['mode']

      self.linkState = object_hash['linkState']

      self.nodewwn = object_hash['nodeWWN']

      self.portwwn = object_hash['portWWN']

      self.type = object_hash['type']

      self.hwaddr = object_hash['HWAddr']

      self.protocol = object_hash['protocol']

      self.label = object_hash['label']

      self.device = object_hash['device']

      !object_hash['partnerPos'].nil? ? self.partner_pos = PortPos.new(object_hash['partnerPos']) : self.partner_pos = nil

      self.failover_state = object_hash['failoverState']

      self.ip_addr = object_hash['IPAddr']

      self.iscsi_name = object_hash['iSCSIName']

      self.enode_macaddr = object_hash['enodeMACAddr']

      self.pfcmask = object_hash['pfcMask']

      !object_hash['iSCSIPortInfo'].nil? ? self.iscsi_portinfo = ISCSIPortInfo.new(object_hash['iSCSIPortInfo']) : self.iscsi_portinfo = nil

    end

  end


  class ISCSIPortInfo

    # [type - String]
    # iSCSI port only, not included in the JSON object for other ports.
    attr_accessor :ip_addr

    # [type - String]
    # iSCSI port only, not included in the JSON object for other ports.
    attr_accessor :iscsi_name

    # [type - String]
    # Netmask for Ethernet port.
    attr_accessor :netmask

    # [type - String]
    # IP address of the gateway.
    attr_accessor :gateway

    # [type - Number]
    # MTU size in bytes.
    attr_accessor :mtu

    # [type - Boolean]
    # Send Targets Group Tag of the iSCSI target
    attr_accessor :stgt

    # [type - Number]
    # TCP port number for the iSNS server.
    attr_accessor :isns_port

    # [type - String]
    # iSNS server IP address.
    attr_accessor :isns_addr

    # [type - String]
    # Data transfer rate for the iSCSI port
    attr_accessor :rate

    # [type - Number]
    # Target portal group tag.
    attr_accessor :tpgt

    # [type - Boolean]
    # Indicates whether the port supports VLANs.
    attr_accessor :vlans

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.ip_addr = object_hash['ipAddr']

      self.iscsi_name = object_hash['iSCSIName']

      self.netmask = object_hash['netmask']

      self.gateway = object_hash['gateway']

      self.mtu = object_hash['mtu']

      self.stgt = object_hash['stgt']

      self.isns_port = object_hash['iSNSPort']

      self.isns_addr = object_hash['iSNSAddr']

      self.rate = object_hash['rate']

      self.tpgt = object_hash['tpgt']

      self.vlans = object_hash['vlans']

    end
  end

  class VolumeSet

    # [type - String]
    # Name of the set.
    attr_accessor :name

    # [type - String]
    # UUID of the set.
    attr_accessor :uuid

    # [type - Number]
    # Set identifier.
    attr_accessor :id

    # [type - String]
    # Comment for the set.
    attr_accessor :comment

    # [type - String]
    # Set domain.
    attr_accessor :domain

    # [type - Array of String]
    # The members of the set.
    attr_accessor :setmembers

    # [type - Number]
    # The flashCachePolicy
    # member is valid for volumes sets
    # only. - Hpe3parSdk::FlashCachePolicy
    attr_accessor :flash_cache_policy

    # [type - Boolean]
    # true: Enabled vvset QoS rule.
    # false: Disabled vvset QoS rules.
    attr_accessor :qos_enabled

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.name = object_hash['name']

      self.uuid = object_hash['uuid']

      self.id = object_hash['id']

      self.comment = object_hash['comment']

      self.domain = object_hash['domain']

      self.setmembers = object_hash['setmembers']

      self.flash_cache_policy = object_hash['flashCachePolicy']

      self.qos_enabled = object_hash['qosEnabled']

    end
  end

  class Space

    # [type - Number]
    # Reserved space in MiB.
    attr_accessor :reserved_MiB

    # [type - Number]
    # Raw reserved space in MiB.
    attr_accessor :raw_reserved_MiB

    # [type - Number]
    # Used space in MiB.
    attr_accessor :used_MiB

    # [type - Number]
    # Free space in MiB.
    attr_accessor :free_MiB

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.reserved_MiB = object_hash['reservedMiB']

      self.raw_reserved_MiB = object_hash['rawReservedMiB']

      self.used_MiB = object_hash['usedMiB']

      self.free_MiB = object_hash['freeMiB']

    end
  end


  class LDLayoutCapacity

    # [type - Number]
    # Raw free capacity in MiB.
    attr_accessor :rawfree_in_mib

    # [type - Number]
    # LD free capacity in MiB.
    attr_accessor :usable_free_in_mib

    # [type - Number]
    # System contains an over provisioned Virtual Size MiB.
    attr_accessor :overprovisioned_virtualsize_in_mib

    # [type - Number]
    # System contains an over provisioned used MiB.
    attr_accessor :overprovisioned_used_in_mib

    # [type - Number]
    # System contains an over provisioned allocated MiB.
    attr_accessor :overprovisioned_allocated_in_mib

    # [type - Number]
    # System contains an over provisioned free MiB.
    attr_accessor :overprovisioned_free_in_mib

    # [type - CapEfficiency]
    # Capacity efficiency attributes.
    attr_accessor :capacitefficiency

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.rawfree_in_mib = object_hash['rawFreeMiB']

      self.usable_free_in_mib = object_hash['usableFreeMiB']

      self.overprovisioned_virtualsize_in_mib = object_hash['overProvisionedVirtualSizeMiB']

      self.overprovisioned_used_in_mib= object_hash['overProvisionedUsedMiB']

      self.overprovisioned_allocated_in_mib = object_hash['overProvisionedAllocatedMiB']

      self.overprovisioned_free_in_mib = object_hash['overProvisionedFreeMiB']

      self.capacitefficiency = CapEfficiency.new(object_hash['capacityEfficiency'])

    end
  end

  class CapEfficiency

    # [type - Number]
    # The compaction ratio indicates the overall amount of storage space saved with 3PAR thin technology.
    attr_accessor :compaction

    # [type - Number]
    # Indicates the amount of storage space saved using Compression.
    attr_accessor :compression

    # [type - Number]
    # Indicates the amount of storage space saved using deduplication and compression together.
    attr_accessor :data_reduction

    # [type - Number]
    # Overprovisioning ratio.
    attr_accessor :over_provisioning

    # [type - Number]
    # The deduplication ratio indicates the amount of storage space saved with 3PAR thin deduplication.
    attr_accessor :deduplication

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.compaction = object_hash['compaction']

      self.compression = object_hash['compression']

      self.data_reduction = object_hash['dataReduction']

      self.over_provisioning = object_hash['overProvisioning']

      self.deduplication = object_hash['deduplication']

    end
  end


  class Policy

    # [type - Boolean]
    # true: Stale snapshots. If there is no space for a copyon-
    # write operation, the snapshot can go stale but the
    # host write proceeds without an error.
    # false: No stale snapshots. If there is no space for a
    # copy-on-write operation, the host write fails.
    attr_accessor :stale_ss

    # [type - Boolean]
    # true: Indicates a volume is constrained to export to
    # one host or one host cluster.
    # false: Indicates a volume exported to multiple hosts
    # for use by a cluster-aware application, or when port
    # presents VLUNs are used
    attr_accessor :one_host

    # [type - Boolean]
    # true: Indicates that the storage system scans for
    # zeros in the incoming write data.
    # false: Indicates that the storage system does not
    # scan for zeros in the incoming write data.
    attr_accessor :zero_detect

    # [type - Boolean]
    # true: Special volume used by the system.
    # false: Normal user volume.
    attr_accessor :system

    # [type - Boolean]
    # This is a read-only policy and cannot be set.
    # true: Indicates that the storage system is enabled for
    # write caching, read caching, and read ahead for the
    # volume.
    # false: Indicates that the storage system is disabled
    # for write caching, read caching, and read ahead for the
    # volume.
    attr_accessor :caching

    # [type - Boolean]
    # true: Stale snapshots. If there is no space for a copyon-
    #write operation, the snapshot can go stale but the
    #host write proceeds without an error.
    #false: No stale snapshots. If there is no space for a
    #copy-on-write operation, the host write fails.
    attr_accessor :fsvc

    # [type - Number]
    # Type of host based DIF policy. - Hpe3parSdk::VolumeHostDIF
    attr_accessor :host_dif

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.stale_ss = object_hash['staleSS']

      self.one_host = object_hash['oneHost']

      self.zero_detect = object_hash['zeroDetect']

      self.system = object_hash['system']

      self.caching = object_hash['caching']

      self.fsvc = object_hash['fsvc']

      self.host_dif = object_hash['hostDIF']

    end
  end

  class FCPath

    # [type - String]
    # A WWN assigned to the host.
    attr_accessor :wwn

    # [type - PortPos]
    # The portpos details.
    attr_accessor :port_pos

    # [type - String]
    # HBA firmware version.
    attr_accessor :firmware_version

    # [type - String]
    # HBA vendor.
    attr_accessor :vendor

    # [type - String]
    # HBA model.
    attr_accessor :model

    # [type - String]
    # HBA driver version.
    attr_accessor :driver_version

    # [type - String]
    # HBA host speed.
    attr_accessor :host_speed

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.wwn = object_hash['wwn']

      !object_hash['portPos'].nil? ? self.port_pos = PortPos.new(object_hash['portPos']) : self.port_pos = nil

      self.firmware_version = object_hash['firmwareVersion']

      self.vendor = object_hash['vendor']

      self.model = object_hash['model']

      self.driver_version = object_hash['driverVersion']

      self.host_speed = object_hash['hostSpeed']

    end
  end

  class SCSIPath

    # [type - String]
    # An iSCSI name to be assigned to the host.
    attr_accessor :name

    # [type - PortPos]
    # The portpos details.
    attr_accessor :port_pos

    # [type - String]
    # IP address for Remote Copy.
    attr_accessor :ipaddr

    # [type - String]
    # HBA firmware version.
    attr_accessor :firmware_version

    # [type - String]
    # HBA vendor.
    attr_accessor :vendor

    # [type - String]
    # HBA model.
    attr_accessor :model

    # [type - String]
    # HBA driver version.
    attr_accessor :driver_version

    # [type - String]
    # HBA host speed.
    attr_accessor :host_speed

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.name = object_hash['name']

      !object_hash['portPos'].nil? ? self.port_pos = PortPos.new(object_hash['portPos']) : self.port_pos = nil

      self.ipaddr = object_hash['IPAddr']

      self.firmware_version = object_hash['firmwareVersion']

      self.vendor = object_hash['vendor']

      self.model = object_hash['model']

      self.driver_version = object_hash['driverVersion']

      self.host_speed = object_hash['hostSpeed']

    end
  end

  class Descriptors

    # [type - String]
    # The host’s location.
    attr_accessor :location

    # [type - String]
    # The host’s IP address.
    attr_accessor :ipaddr

    # [type - String]
    # The operating system running on the host.
    attr_accessor :os

    # [type - String]
    # The host’s model.
    attr_accessor :model

    # [type - String]
    # The host’s owner and contact.
    attr_accessor :contact

    # [type - String]
    # Any additional information for the host.
    attr_accessor :comment

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.location = object_hash['location']

      self.ipaddr = object_hash['IPAddr']

      self.os = object_hash['os']

      self.model = object_hash['model']

      self.contact = object_hash['contact']

      self.comment = object_hash['comment']
    end
  end

  class Agent

    # [type - String]
    # The host name reported by the agent.
    attr_accessor :reported_name

    # [type - String]
    # The host agent IP address.
    attr_accessor :ipaddr

    # [type - String]
    # The architecture description of the host agent.
    attr_accessor :architecture

    # [type - String]
    # Operating system of the host agent.
    attr_accessor :os

    # [type - String]
    # The operating system version of the host agent.
    attr_accessor :os_version

    # [type - String]
    # The operating system patch level of host agent.
    attr_accessor :os_patch

    # [type - String]
    # The multipathing software in use by the host agent.
    attr_accessor :multi_path_software

    # [type - String]
    # The multipathing software version.
    attr_accessor :multi_path_software_version

    # [type - String]
    # Name of the host cluster of which the host is a member.
    attr_accessor :cluster_name

    # [type - String]
    # Host clustering software in use on host.
    attr_accessor :cluster_software

    # [type - String]
    # Version of the host clustering software in use.
    attr_accessor :cluster_version

    # [type - String]
    # Identifier for the cluster.
    attr_accessor :cluster_id

    # [type - String]
    # Identifier for the host agent.
    attr_accessor :hosted

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.reported_name = object_hash['reportedName']

      self.ipaddr = object_hash['IPAddr']

      self.architecture = object_hash['architecture']

      self.os = object_hash['os']

      self.os_version = object_hash['osVersion']

      self.os_patch = object_hash['osPatch']

      self.multi_path_software = object_hash['multiPathSoftware']

      self.multi_path_software_version = object_hash['multiPathSoftwareVersion']

      self.cluster_name = object_hash['clusterName']

      self.cluster_software = object_hash['clusterSoftware']

      self.cluster_version = object_hash['clusterVersion']

      self.cluster_id = object_hash['clusterId']

      self.hosted = object_hash['hosted']

    end
  end

  class PortPos

    # [type - Number]
    # System node.
    attr_accessor :node

    # [type - Number]
    # PCI bus slot in the node.
    attr_accessor :slot

    # [type - Number]
    # Port number on the FC card.
    attr_accessor :card_port

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.node = object_hash['node']

      self.slot = object_hash['slot']

      self.card_port = object_hash['cardPort']

    end
  end

  class Usage

    # [type - Number]
    # Total logical disk space in MiB.
    attr_accessor :total_MiB

    # [type - Number]
    # Total physical (raw) logical disk space in MiB.
    attr_accessor :raw_total_MiB

    # [type - Number]
    # Amount of logical disk used, in MiB.
    attr_accessor :used_MiB

    # [type - Number]
    # Amount of physical (raw) logical disk used, in MiB.
    attr_accessor :raw_used_MiB

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.total_MiB = object_hash['totalMiB']

      self.raw_total_MiB = object_hash['rawTotalMiB']

      self.used_MiB = object_hash['usedMiB']

      self.raw_used_MiB = object_hash['rawUsedMiB']

    end
  end

  class GrowthParams

    # [type - Number]
    # The growth increment, the amount of logical disk storage created on each auto-grow operation.
    attr_accessor :increment_MiB

    # [type - LDLayout]
    # Logical disk types for this CPG.
    attr_accessor :ld_layout

    # [type - Number]
    # Threshold of used logical disk space, when exceeded, results in a warning alert.
    attr_accessor :warning_MiB

    # [type - Number]
    # The auto-grow operation is limited to the specified storage amount that sets the growth limit.
    attr_accessor :limit_MiB

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.warning_MiB = object_hash['warningMiB']

      self.limit_MiB = object_hash['limitMiB']

      self.increment_MiB = object_hash['incrementMiB']

      self.ld_layout = LDLayout.new(object_hash['LDLayout'])

    end
  end

  class PrivateSpace

    # [type - Number]
    # Base space in MiB.
    attr_accessor :base

    # [type - Number]
    # Raw base space in MiB.
    attr_accessor :raw_base

    # [type - Number]
    # snapshot space in MiB.
    attr_accessor :snapshot

    # [type - Number]
    # Raw snapshot space in MiB.
    attr_accessor :raw_snapshot

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.base = object_hash['base']

      self.raw_base = object_hash['rawBase']

      self.snapshot = object_hash['snapshot']

      self.raw_snapshot = object_hash['rawSnapshot']

    end
  end

  class LDLayout

    # [type - Number]
    # Specifies the RAID type for the logical disk. - Hpe3parSdk::CPGRAIDType
    attr_accessor :raidtype

    # [type - Number]
    # Specifies the set size in the number of chunklets.
    attr_accessor :set_size

    # [type - Number]
    # Specifies that the layout must support the failure of one port pair, one cage, or one magazine. - Hpe3parSdk::CPGHA
    attr_accessor :ha

    # [type - Number]
    # Specifies the chunklet location preference characteristics. - Hpe3parSdk::CPGChunkletPosPref
    attr_accessor :chunklet_pos_pref

    # [type - Array of DiskPattern objects]
    # Specifies patterns for candidate disks.
    attr_accessor :disk_patterns

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.raidtype = object_hash['RAIDType']

      self.set_size = object_hash['setSize']

      self.ha = object_hash['HA']

      self.chunklet_pos_pref = object_hash['chunkletPosPref']

      self.disk_patterns = []
      if !object_hash['diskPatterns'].nil?
        object_hash['diskPatterns'].each do |disk_pattern|
          self.disk_patterns.push(DiskPattern.new(disk_pattern))
        end
      end
    end
  end

  class DiskPattern

    # [type - String]
    # Specifies one or more nodes. Nodes are identified by one or more integers. Multiple nodes are separated with a single comma (1,2,3). A range of nodes is separated with a hyphen (0–7). The primary path of the disks must be on the specified node number.
    attr_accessor :node_list

    # [type - String]
    # Specifies one or more PCI slots. Slots are identified by one or more integers. Multiple slots are separated with a single comma (1,2,3). A range of slots is separated with a hyphen (0–7). The primary path of the disks must be on the specified PCI slot number(s).
    attr_accessor :slot_list

    # [type - String]
    # Specifies one or more ports. Ports are identified by one or more integers. Multiple ports are separated with a single comma (1,2,3). A range of ports is separated with a hyphen (0–4). The primary path of the disks must be on the specified port number(s).
    attr_accessor :port_list

    # [type - String]
    # Specifies one or more drive cages. Drive cages are identified by one or more integers. Multiple drive cages are separated with a single comma (1,2,3). A range of drive cages is separated with a hyphen (0– 3). The specified drive cage(s) must contain disks.
    attr_accessor :cage_list

    # [type - String]
    # Specifies one or more drive magazines. Drive magazines are identified by one or more integers. Multiple drive magazines are separated with a single comma (1,2,3). A range of drive magazines is separated with a hyphen (0–7). The specified magazine(s) must contain disks.
    attr_accessor :mag_list

    # [type - String]
    # Specifies one or more disk positions within a drive magazine. Disk positions are identified by one or more integers. Multiple disk positions are separated with a single comma (1,2,3). A range of disk positions is separated with a hyphen (0–3). The specified portion(s) must contain disks.
    attr_accessor :disk_pos_list

    # [type - String]
    # Specifies one or more physical disks. Disks are identified by one or more integers. Multiple disks are separated with a single comma (1,2,3). A range of disks is separated with a hyphen (0–3). Disks must match the specified ID(s).
    attr_accessor :disk_list

    # [type - Number]
    # Specifies that physical disks with total chunklets greater than the number specified be selected.
    attr_accessor :total_chunklets_greater_than

    # [type - Number]
    # Specifies that physical disks with total chunklets less than the number specified be selected.
    attr_accessor :total_chunklets_less_than

    # [type - Number]
    # Specifies that physical disks with free chunklets less than the number specified be selected.
    attr_accessor :free_chunklets_greater_than

    # [type - Number]
    # Specifies that physical disks with free chunklets greater than the number specified be selected.
    attr_accessor :free_chunklets_less_than

    # [type - array of string]
    # Specifies that PDs identified by their models are selected.
    attr_accessor :disk_models

    # [type - Number]
    # Specifies that physical disks must have the specified device type. - Hpe3parSdk::CPGDiskType
    attr_accessor :disk_type

    # [type - Number]
    # Disks must be of the specified speed.
    attr_accessor :rpm

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.node_list = object_hash['nodeList']

      self.slot_list = object_hash['slotList']

      self.port_list = object_hash['portList']

      self.cage_list = object_hash['cageList']

      self.mag_list = object_hash['magList']

      self.disk_pos_list = object_hash['diskPosList']

      self.disk_list = object_hash['diskList']

      self.total_chunklets_greater_than = object_hash['totalChunkletsGreaterThan']

      self.total_chunklets_less_than = object_hash['totalChunkletsLessThan']

      self.free_chunklets_greater_than = object_hash['freeChunkletsGreaterThan']

      self.free_chunklets_less_than = object_hash['freeChunkletsLessThan']

      self.disk_models = object_hash['diskModels']

      self.disk_type = object_hash['diskType']

      self.rpm = object_hash['RPM']

    end
  end

  class Task

    # [type - Number]
    # Task ID.
    attr_accessor :task_id

    # [type - Number]
    # Task Status.
    attr_accessor :status

    # [type - String]
    # Task name.
    attr_accessor :name

    # [type - Number]
    # Task type.
    attr_accessor :type

    def initialize(object_hash)
      if object_hash == nil
        return
      end

      self.task_id = object_hash['id']

      self.status = object_hash['status']

      self.name = object_hash['name']

      self.type = object_hash['type']
    end
  end
end