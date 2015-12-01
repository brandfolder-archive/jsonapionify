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

task :default => :spec
