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

require 'bundler/gem_tasks'
require 'rake/clean'

task :console do
  exec 'irb -r Hpe3parSdk -I ./lib'
end

namespace :build do
  begin
    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new(:spec) do |t|
      puts '', 'RSpec Task started....'
      t.pattern = Dir.glob('spec/**/*_spec.rb')
      t.rspec_opts = '--format html --out test_reports/rspec_results.html'
      t.fail_on_error = true
    end

    task default: :spec
  rescue LoadError => le
    # no rspec available
    puts "(#{le.message})"
  end

  begin
    require 'rubocop/rake_task'
    desc 'Run RuboCop - Ruby static code analyzer'
    RuboCop::RakeTask.new(:rubocop) do |task|
      puts '', 'Rubocop Task started....'
      # task.patterns = ['lib/**/*.rb']
      task.fail_on_error = false
      task.formatters = ['html']
      task.options = ['--out', 'rubocop_report.html']
    end
  rescue LoadError => le
    # no rspec available
    puts "(#{le.message})"
  end


# $stdout.reopen("ruby_lint_report.txt", "w")
# $stdout.sync = true
  require 'ruby-lint/rake_task'
  RubyLint::RakeTask.new do |task|
    task.name = 'lint'
    task.description = 'Rake task to run ruby-lint on lib'
    task.debug = TrueClass
    task.files = ['./lib/']
    # task.configuration = ''
  end
# $stdout = STDOUT

  require 'rdoc/task'
  Rake::RDocTask.new(:rdoc) do |rd|
    rd.title = 'Ruby 3PAR Library'
    rd.rdoc_files.include('lib/**/*.rb', 'README.md')
    rd.rdoc_dir = 'rdoc'
    rd.main = 'README.md'
  end

  desc 'Clean up previous build'
  task :clobber do
    CLOBBER << 'rubocop_report.html'
    CLOBBER << 'test_reports'
    CLOBBER << 'coverage'
    CLOBBER << 'Gemfile.lock'
    Rake::Task['clobber'].invoke
    Rake::Task['build:clobber_rdoc'].invoke
  end

  require 'bundler/inline'

  task :deploy do
    gemfile(true) do
      source 'https://rubygems.org'
      gem 'nexus'
    end
  end


end

desc 'Run RDoc, ruby-lint, rubocop, unit tests, coverage and generate gemfile of the project'
task :build_client do
  Rake::Task['build:clobber'].invoke
  Rake::Task['build:spec'].invoke
  Rake::Task['build'].invoke
  Rake::Task['build:rdoc'].invoke
  Rake::Task['build:lint'].invoke
  Rake::Task['build:rubocop'].invoke
  Rake::Task['build:deploy'].invoke
end
