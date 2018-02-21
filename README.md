[![Gem Version](https://badge.fury.io/rb/hpe3par_sdk.png)](https://badge.fury.io/rb/hpe3par_sdk)   [![Build Status](https://travis-ci.org/HewlettPackard/hpe3par_ruby_sdk.svg?branch=master)](https://travis-ci.org/HewlettPackard/hpe3par_ruby_sdk)

HPE 3PAR Software Development Kit for Ruby
====================
This is a Client library that can talk to the HPE 3PAR Storage array.  The 3PAR
storage array has a REST web service interface and a command line interface.
This client library implements a simple interface for talking with either
interface, as needed.  The HTTParty library is used to communicate
with the REST interface.  The net/ssh library is used to communicate
with the command line interface over an SSH connection.


Requirements
============
* 3PAR OS - 3.2.2 MU6, 3.3.1 MU1
* Ruby - 2.4.x or higher.
* WSAPI service should be enabled on the 3PAR storage array.

Capabilities
============
* create_volume
* delete_volume
* modify_volume
* grow_volume
* tune_volume
* get_volume
* get_volumes
* get_volume_by_wwn

* create_volume_set
* delete_volume_set
* modify_volume_set
* add_volumes_to_volume_set
* remove_volumes_from_volume_set
* create_snapshot_of_volume_set
* get_volume_sets
* get_volume_set
* get_all_volume_sets_for_volume


* create_snapshot
* restore_snapshot
* delete_snapshot
* get_snapshots
* get_volume_snapshots

* get_ports
* get_fc_ports
* get_iscsi_ports
* get_ip_ports

* get_cpgs
* get_cpg
* create_cpg
* delete_cpg
* modify_cpg
* get_cpg_available_space

* create_physical_copy
* copy_physical_copy
* resync_physical_copy
* delete_physical_copy
* get_online_physical_copy_status
* stop_offline_physical_copy
* stop_online_physical_copy

* create_flash_cache
* get_flash_cache
* delete_flash_cache
* get_storage_system_info
* get_overall_system_capacity

* wait_for_task_to_end
* cancel_task
* get_all_tasks
* get_task

* create_vlun
* delete_vlun
* get_vlun
* get_vluns
* get_host_vluns

* create_qos_rules
* modify_qos_rules
* delete_qos_rules
* query_qos_rules
* query_qos_rule

* create_host
* modify_host
* delete_host
* get_hosts
* get_host
* query_host_by_fc_path
* query_host_by_iscsi_path

* create_host_set
* delete_host_set
* modify_host_set
* get_host_set
* get_host_sets
* find_host_sets
* add_hosts_to_host_set
* remove_hosts_from_host_set

* get_ws_api_configuration_info


Installation
============

To install:
```bash
 $ gem install hpe3par_sdk
```

or

Require the gem in your gemfile:
```ruby
   gem 'hpe3par_sdk'
```
Then run <code>$ bundle install</code>

Usage
=============
```ruby
 #Create an instance of Hpe3parSdk::Client
 cl = Hpe3parSdk::Client.new('https://my3pararray:8080/api/v1')

 #Login using 3PAR credentials
 cl.login('storage_user', 'mypassword')

 #Call any of the methods on the client instance
 cl.create_volume('db_volume', 'FC_r1', 3209890,{:tpvv => true, :tdvv => false})

 #Logout once you have finished all of your operations
 cl.logout
```

Unit Tests
==========

To run all unit tests:
```bash
 $ rake build:spec
```
The output of the coverage tests will be placed into the ``coverage`` dir.

To run a specific test:
```bash
 $ rspec spec/client_spec.rb
```

Build
=====
To build the gem:
```bash
$ rake build_client
```

Documentation
=============

To build the documentation:
```bash
 $ rake build:rdoc
```
To view the built documentation point your browser to:

 rdoc/index.html


Feature Requests
-----------------
If you have a need that is not met by the current implementation, please let us know by creating a new issue.
You must sign a Contributor License Agreement first. Contact one of the authors (from Hewlett Packard Enterprise) for details and the CLA.

How to contribute
============
1. Fork the repository on Github
2. Create a named feature branch (like `feature_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

Note: HPE reserves the right to reject changes that do not fit the scope of this project, so for feature additions, please open an issue to discuss your ideas before doing the work.

## License
This project is licensed under the Apache 2.0 license. Please see [LICENSE](LICENSE) for more info

Maintainer: Hewlett Packard Enterprise (<hpe_storage_ruby_sdk@groups.ext.hpe.com>)