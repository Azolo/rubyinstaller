require 'erb'
require 'rubygems'

interpreters = [RubyInstaller::Ruby18, RubyInstaller::Ruby19]

gem 'rdoc'
require 'rdoc/rdoc'
require 'rdoc/task'
require 'rdoc/options'

doc_files = File.join('docs', '.')
resources = File.join(RubyInstaller::ROOT, 'resources', doc_files)

format = ENV['format'] || 'chm'

interpreters.each do |package|
  namespace package.short_version do
    
      namespace :docs do
        package.docs.each do |doc|
          desc "TEST"
          task doc.lib => [:prepare] do
            options = RDoc::Options.new
            options.main_page = 'ruby_installer/README'
            options.title = doc.title
            options.op_dir = doc.target
            options.exclude << doc.exclude if doc.exclude
            options.verbosity = 1
            options.setup_generator format
            options.encoding = "UTF-8"
            # $DEBUG_RDOC = true
  
            options.files ||= []
            options.files.concat doc.files
            options.files << options.main_page
  
            cd package.target do
              puts "\nBuilding Docs with #{options.generator}"
              rdoc = RDoc::RDoc.new
              rdoc.document(options)
            end
          end

          # Need to prepare by copying some files
          task :prepare do
            cp_r resources, File.join(package.target, 'ruby_installer')
          end
        end 
      end

      task :docs => ["docs:combination"]
    
      ##
      # redocs
      ##

      namespace :redocs do
        package.docs.each do |doc|
          task doc.lib => ["^clobber_docs:#{doc.lib}", "^docs:#{doc.lib}"]
        end
      end

      task :redocs => [:clobber_docs, :docs]

      ##
      # clobber_docs
      ##

      namespace :clobber_docs do
        package.docs.each do |doc|
          task doc.lib do
            rm_rf doc.target
          end
        end
      end

      task :clobber_docs do
        rm_rf package.doc_target
      end
  end
end
