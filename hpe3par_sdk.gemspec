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

# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'Hpe3parSdk/version'

Gem::Specification.new do |spec|
  spec.name          = 'hpe3par_sdk'
  spec.version       = Hpe3parSdk::VERSION
  spec.authors       = ['Hewlett Packard Enterprise']
  spec.email         = ['hpe_storage_ruby_sdk@groups.ext.hpe.com']

  spec.summary       = 'HPE 3PAR Software Development Kit for Ruby'
  spec.description   = 'HPE 3PAR Software Development Kit for Ruby'
  spec.homepage      = 'https://github.com/HewlettPackard/hpe3par_ruby_sdk'
  spec.license      =  'Apache-2.0'


  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2'

  spec.add_dependency 'net-ssh', '~> 4'
  spec.add_runtime_dependency 'httparty', '~> 0.15.6'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.52'
  spec.add_development_dependency 'simplecov', '~> 0.15.0'
  spec.add_development_dependency 'ruby-lint', '~> 2.0', '>= 2.0.4'
end
