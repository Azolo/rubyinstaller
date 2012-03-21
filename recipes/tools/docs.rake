require 'erb'
require 'rubygems'

interpreters = [RubyInstaller::Ruby18, RubyInstaller::Ruby19]

begin
  gem 'rdoc'
  require 'rdoc/rdoc'
  gem 'rdoc_chm', '~> 2.4.3'
rescue Gem::LoadError
  if Rake.application.options.show_tasks
    puts "You need rdoc 2.5.11 and rdoc_chm 2.4.2 gems installed"
    puts "in order to build the docs tasks."
    puts "Try `gem install rdoc -v 2.5.11` and later `gem install rdoc_chm -v 2.4.2`"
    puts
  end
  interpreters = []
end

namespace :docs do
  task :htmlhelp do
    executable = 'hhc.exe'
    path = File.join(ENV['ProgramFiles'], 'HTML Help Workshop', executable)
    unless File.exist?(path) && File.executable?(path)
      puts <<-EOT
To generate CHM documentation you need Microsoft's Html Help Workshop installed.

You can download a copy for free from:

    http://msdn.microsoft.com/library/default.asp?url=/library/en-us/htmlhelp/html/hwMicrosoftHTMLHelpDownloads.asp
EOT
      fail "HtmlHelp is required"
    end
  end
end

interpreters.each do |package|
  short_ver    = package.version.gsub('.', '')[0..1]
  version      = "ruby#{short_ver}"
  doc_dir      = File.join(RubyInstaller::ROOT, 'sandbox', 'doc')
  target       = File.join(doc_dir, version)

  core_glob    = File.join(package.target, "*.c")
  core_files   = Dir.glob(core_glob).map{ |f| File.basename(f) }

  stdlib_files = ['./lib', './ext']

  default_opts = ['--format=chm', '--debug', "--encoding=UTF-8"]

  # build file dependencies
  rdocs = [
    {
      :file  => "#{version}-core.chm",
      :title => "Ruby #{package.version} Core",
      :files => core_files,
    },
    {
      :file  => "#{version}-stdlib.chm",
      :title => "Ruby #{package.version} Standard Library",
      :files => stdlib_files,
      :opts  => ["-x", "./lib/rdoc"]
    }
  ]

  meta_chm = OpenStruct.new(
    :title => "Ruby #{package.version} Help file",
    :file  => File.join(target, "#{version}.chm")
  )

  rdocs.each do |chm|
    chm_file = File.join(target, chm[:file])

    file chm_file do
      cd package.target do
        dirname = File.basename(chm_file, '.chm')
        op_dir  = File.join(target, dirname)
        title   = "#{chm[:title]} API Reference"

        # create documentation
        args = default_opts +
              (chm[:opts] || []) +
              ['--title', title, '--op', op_dir] +
              chm[:files]

        rdoc = RDoc::RDoc.new
        rdoc.document(args)

        cp File.join(op_dir, File.basename(chm[:file])), chm_file
      end
    end

    # meta package depends on individual chm files
    file meta_chm.file => [chm_file]
  end

  # generate index
  index = File.join(target, 'index.html')

  file index do
    cd target do
      cp File.join(RubyInstaller::ROOT, 'resources', 'chm', 'README.txt'), '.'
      op_dir = File.join(target, 'README')

      # create documentation
      opts = ['--op', op_dir, '--title', 'RubyInstaller', 'README.txt']
      rdoc = RDoc::RDoc.new
      rdoc.document(default_opts + opts)

      images = File.join(op_dir, 'images')
      js = File.join(op_dir, 'js')

      cp_r(images, target) if File.exist?(images)
      cp_r(js, target) if File.exist?(js)

      cp File.join(op_dir, 'rdoc.css'), target
      cp File.join(op_dir, 'README_txt.html'), index
    end
  end

  # add index to the metapackge dependency
  file meta_chm.file => [index]

  # generate meta package
  file meta_chm.file do
    cd target do

      meta_chm.files = Dir.glob('*.html')
      meta_chm.merge_files = Dir.glob('*.chm')
      source = File.join(RubyInstaller::ROOT, 'resources', 'chm', '*.rhtml')

      Dir.glob(source).each do |rhtml_file|
        File.open(File.basename(rhtml_file, '.rhtml'), 'w') do |output_file|
          output = ERB.new(File.read(rhtml_file), 0).result(binding)
          output_file.write(output)
        end
      end

      Dir.glob('*.hhp').each do |hhp|
        system RDoc::Generator::CHM::HHC_PATH, hhp
      end
    end
  end

  namespace version do
    task :chm_clobber_docs do
      rm_rf target
    end

    desc "build chm docs for #{version}"
    task :chm_docs => ['docs:htmlhelp', meta_chm.file]

    desc "rebuild chm docs for #{version}"
    task :chm_redocs => [:chm_clobber_docs, :chm_docs]
  end
end
