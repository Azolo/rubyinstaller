require 'erb'
require 'rubygems'

interpreters = [RubyInstaller::Ruby18, RubyInstaller::Ruby19]

gem 'rdoc'
require 'rdoc/rdoc'
require 'rdoc/task'
require 'rdoc/options'

interpreters.each do |package|
  short_ver    = package.version.gsub('.', '')[0..1]
  version      = "ruby#{short_ver}"
  doc_dir      = File.join(RubyInstaller::ROOT, 'sandbox', 'doc_test')
  target       = File.join(doc_dir, version)

  core_glob    = File.join(package.target, "*.c")
  core_files   = Dir.glob(core_glob)

  stdlib_files = [
    File.join(package.target, '/lib'),
    File.join(package.target, '/ext')
  ]


  # build file dependencies
  rdocs = [
    {
      :dir  => "#{version}-core",
      :title => "Ruby #{package.version} Core",
      :files => core_files
    },
    {
      :dir  => "#{version}-stdlib",
      :title => "Ruby #{package.version} Standard Library",
      :files => stdlib_files,
      :exclude  => "./lib/rdoc"
    }
  ]

  namespace version do
    rdocs.each do |doc|
      desc "TEST"
      task [doc[:dir]] do

        op_dir  = File.join(target, doc[:dir])
        title   = "#{doc[:title]} API Reference"

        options = RDoc::Options.new
        options.title = title
        options.op_dir = op_dir
        options.exclude << doc[:exclude] if doc[:exclude]
        options.verbosity = 1
        options.setup_generator 'darkfish'
        options.encoding = "UTF-8"

        options.files = []
        options.files.concat doc[:files]
        puts options.inspect

        rdoc = RDoc::RDoc.new
        rdoc.document(options)
      end
    end
  end
end
