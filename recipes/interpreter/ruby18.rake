require 'rake'
require 'rake/clean'
require 'pathname'

namespace(:interpreter) do
  namespace(:ruby18) do
    package = RubyInstaller::Ruby18
    task :install do
      full_install_target = File.expand_path(File.join(RubyInstaller::ROOT, package.install_target))
      full_install_target_nodrive = full_install_target.gsub(/\A[a-z]:/i, '')

      rbconfig = File.join(package.install_target, 'lib/ruby/1.8/i386-mingw32/rbconfig.rb')
      contents = File.read(rbconfig).
        gsub(/#{Regexp.escape(full_install_target)}/) { |match| "" }.
      gsub(/#{Regexp.escape(full_install_target_nodrive)}/) { |match| "" }.
      gsub('$(DESTDIR)', '$(exec_prefix)').
      gsub('CONFIG["exec_prefix"] = "$(exec_prefix)"', 'CONFIG["exec_prefix"] = "$(prefix)"')

      File.open(rbconfig, 'w') { |f| f.write(contents) }

      # replace the batch files with new and path-clean stubs
      Dir.glob("#{package.install_target}/bin/*.bat").each do |bat|
        File.open(bat, 'w') do |f|
          f.write batch_stub
        end
      end
    end
  end
end

  desc "compile Ruby 1.8"
  task :ruby18 => [
    'interpreter:ruby18:sources',
    'interpreter:ruby18:extract',
    'interpreter:ruby18:prepare',
    'interpreter:ruby18:configure',
    'interpreter:ruby18:compile',
    'interpreter:ruby18:install'
  ]

  namespace :ruby18 do
    task :dependencies => ['interpreter:ruby18:dependencies']
    task :clean => ['interpreter:ruby18:clean']
  end

  unless ENV["NOGEMS"]
    # Add rubygems to the chain
    task :ruby18 => [:rubygems18]

    # Add RubyGems operating system customization
    task :ruby18 => ['tools:rubygems:hook18']
  end

  # add Pure Readline to the chain
  task :ruby18 => [:rbreadline]
  task :ruby18 => ['dependencies:rbreadline:install18']

  # add tcl/tk installation
  unless ENV["NOTK"]
    task :ruby18 => ["dependencies:tk:install18"]
  end

  task :check18 => ['ruby18:dependencies', 'interpreter:ruby18:check']
  task :irb18   => ['ruby18:dependencies', 'interpreter:ruby18:irb']
