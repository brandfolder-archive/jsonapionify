require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'fileutils'

RSpec::Core::RakeTask.new(:spec)

task :missing_tests do
  specs = Dir.glob("./lib/**/*.rb").map do |f|
    f.gsub(/\.\/lib(.*)\.rb/, "./spec\\1_spec.rb")
  end
  specs.each do |f|
    unless File.exist? f
      puts 'created: ' + f
      FileUtils.mkdir_p(File.dirname(f)) && FileUtils.touch(f)
    end
  end
end

STATS_DIRECTORIES = [
  %w(Structure        lib/jsonapionify/structure),
  %w(Server           lib/jsonapionify/api),
  %w(Specs            spec),
].collect do |name, dir|
  [name, "#{File.dirname(Rake.application.rakefile_location)}/#{dir}"]
end.select { |name, dir| File.directory?(dir) }

desc "Report code statistics (KLOCs, etc)"
task :stats do
  require_relative './vendor/code_statistics'
  CodeStatistics.new(*STATS_DIRECTORIES).to_s
end

task :default => :spec
