# frozen_string_literal: true

require 'rake/testtask'
require 'rubocop/rake_task'
require 'rubycritic/rake_task'

module SpeckleSystems
  # Custom utility functions for rake tasks
  module RakeUtils
    module_function

    # Find ruby files that were changed from `main` to the latest revision
    def changed_rb_files(previous_revision: 'main', latest_revision: '')
      range = latest_revision.empty? ? previous_revision : "#{latest_revision}..#{previous_revision}"
      command = "git diff #{range} --name-only"
      changed_files = `#{command}`.split("\n")
      # filter changed files with ruby files (.rb), Gemfile and Rakefile.
      filtered_files = changed_files.grep(/.*\.rb$|Gemfile|Rakefile/)
      filtered_files.select { |file| File.exist?(file) }
    end
  end
end

# Add default rubocop task
RuboCop::RakeTask.new(:default)

# Add task to only verify ruby files that are different than in the `main` branch
desc('Run rubocop on changed files')
RuboCop::RakeTask.new(:rubocop_changed) do |t|
  t.patterns = FileList.new(SpeckleSystems::RakeUtils.changed_rb_files)
end

# Glob pattern to match source files. Defaults to FileList['.'].
ruby_critic_paths = FileList[
  'speckle_connector/**/*.rb',
  'speckle_connector.rb',
  'tests/**/*.rb'] - FileList['_tools/**/*.rb']

# for local
RubyCritic::RakeTask.new('rubycritic') do |task|
  task.paths = ruby_critic_paths
end

# for CI
RubyCritic::RakeTask.new('rubycritic-ci') do |task|
  task.options = '--mode-ci --format console --no-browser --branch main'
  task.paths = ruby_critic_paths
end
