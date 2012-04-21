require 'rake'
require 'rake/clean'
require 'pathname'


namespace(:interpreter) do
  namespace(:tcs) do
    package = RubyInstaller::RubyTCS

    Rake::Task['interpreter:tcs:checkout'].clear
    task :checkout => "downloads" do |t|
      cd RubyInstaller::ROOT do
        # If is there already a checkout, update instead of checkout"
        unless File.exist?(File.join(RubyInstaller::ROOT, package.checkout_target, '.git'))
          sh "git clone #{package.checkout} #{package.checkout_target}"
        end
        cd package.checkout_target do
          sh "git checkout #{package.branch} && git pull"
        end
      end
    end

    task :clean do
      rm_rf package.build_target
      rm_rf package.install_target
    end

    task :download => [:sources]

    Rake::Task['interpreter:tcs:sources'].clear
    task :sources do

      unless ENV['LOCAL']
        Rake::Task["interpreter:#{package.short_version}:checkout"].invoke
      end
    end

    Rake::Task['interpreter:tcs:extract'].clear
    task :extract => [:extract_utils] do
      if ENV['LOCAL']
        package.target = File.expand_path(File.join(ENV['LOCAL'], '.'))
      else
        package.target = File.expand_path(package.checkout_target)
      end
    end
  end
end

desc "compile TCS Ruby"
task :tcs => [
  'interpreter:tcs:sources',
  'interpreter:tcs:extract',
  'interpreter:tcs:prepare',
  'interpreter:tcs:configure',
  'interpreter:tcs:compile',
  'interpreter:tcs:install'
]

namespace :tcs do
  task :dependencies => ['interpreter:tcs:dependencies']
  task :clean => ['interpreter:tcs:clean']
end

unless ENV["NOGEMS"]
  # Add rubygems to the chain
  task :tcs => [:rubygems19]
end

# Add RubyGems operating system customization
task :tcs => ['tools:rubygems:hook19']

# add Pure Readline to the chain
task :tcs => [:rbreadline]
task :tcs => ['dependencies:rbreadline:install19']

# add tcl/tk installation
unless ENV["NOTK"]
  task :tcs => ["dependencies:tk:install19"]
end

task :checktcs   => ['tcs:dependencies', 'interpreter:tcs:check']
task :irbtcs     => ['tcs:dependencies', 'interpreter:tcs:irb']
