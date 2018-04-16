# Change Log

## [Unreleased](https://github.com/HewlettPackard/hpe3par_ruby_sdk/tree/HEAD)

[Full Changelog](https://github.com/HewlettPackard/hpe3par_ruby_sdk/compare/v1.0.0...HEAD)

**Merged pull requests:**

- Delete telemetry metadata before deleting the volume [\#1](https://github.com/HewlettPackard/hpe3par_ruby_sdk/pull/1) ([farhan7500](https://github.com/farhan7500))

## [v1.0.0](https://github.com/HewlettPackard/hpe3par_ruby_sdk/tree/v1.0.0) (2018-01-19)

## HPE 3PAR Software Development Kit for Ruby

This is a Client library that can talk to the HPE 3PAR Storage array. The 3PAR storage array has a REST web service interface and a command line interface. This client library implements a simple interface for talking with either interface, as needed. The HTTParty library is used to communicate with the REST interface. The net/ssh library is used to communicate with the command line interface over an SSH connection.

## Capabilities

    create_volume
    delete_volume
    modify_volume
    grow_volume
    tune_volume
    get_volume
    get_volumes
    get_volume_by_wwn
    create_volume_set
    delete_volume_set
    modify_volume_set
    add_volumes_to_volume_set
    remove_volumes_from_volume_set
    create_snapshot_of_volume_set
    get_volume_sets
    get_volume_set
    get_all_volume_sets_for_volume
    create_snapshot
    restore_snapshot
    delete_snapshot
    get_snapshots
    get_volume_snapshots
    get_ports
    get_fc_ports
    get_iscsi_ports
    get_ip_ports
    get_cpgs
    get_cpg
    create_cpg
    delete_cpg
    modify_cpg
    get_cpg_available_space
    create_physical_copy
    copy_physical_copy
    resync_physical_copy
    delete_physical_copy
    get_online_physical_copy_status
    stop_offline_physical_copy
    stop_online_physical_copy
    create_flash_cache
    get_flash_cache
    delete_flash_cache
    get_storage_system_info
    get_overall_system_capacity
    wait_for_task_to_end
    cancel_task
    get_all_tasks
    get_task
    create_vlun
    delete_vlun
    get_vlun
    get_vluns
    get_host_vluns
    create_qos_rules
    modify_qos_rules
    delete_qos_rules
    query_qos_rules
    query_qos_rule
    create_host
    modify_host
    delete_host
    get_hosts
    get_host
    query_host_by_fc_path
    query_host_by_iscsi_path
    create_host_set
    delete_host_set
    modify_host_set
    get_host_set
    get_host_sets
    find_host_sets
    add_hosts_to_host_set
    remove_hosts_from_host_set
    get_ws_api_configuration_info

