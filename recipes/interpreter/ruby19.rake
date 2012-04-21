require 'rake'
require 'rake/clean'
require 'pathname'

namespace(:interpreter) do
  namespace(:ruby19) do
    package = RubyInstaller::Ruby19
  end
end

desc "compile Ruby 1.9"
task :ruby19 => [
  'interpreter:ruby19:sources',
  'interpreter:ruby19:extract',
  'interpreter:ruby19:prepare',
  'interpreter:ruby19:configure',
  'interpreter:ruby19:compile',
  'interpreter:ruby19:install'
]

namespace :ruby19 do
  task :dependencies => ['interpreter:ruby19:dependencies']
  task :clean => ['interpreter:ruby19:clean']
end

unless ENV["NOGEMS"]
  # Add rubygems to the chain
  task :ruby19 => [:rubygems19]
end

# Add RubyGems operating system customization
task :ruby19 => ['tools:rubygems:hook19']

# add Pure Readline to the chain
task :ruby19 => [:rbreadline]
task :ruby19 => ['dependencies:rbreadline:install19']

# add tcl/tk installation
unless ENV["NOTK"]
  task :ruby19 => ["dependencies:tk:install19"]
end

task :check19   => ['ruby19:dependencies', 'interpreter:ruby19:check']
task :irb19     => ['ruby19:dependencies', 'interpreter:ruby19:irb']
