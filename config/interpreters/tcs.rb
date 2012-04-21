require 'ostruct'

module RubyInstaller
  INTERPRETERS << RubyTCS = OpenStruct.new(
    :version => 'tcs-trunk',
    :short_version => 'tcs',
    :checkout => 'https://github.com/thecodeshop/ruby.git',
    :branch => 'tcs-ruby_1_9_3',
    :checkout_target => 'downloads/tcs',
    :target => 'sandbox/tcs_1_9',
    :build_target => 'sandbox/tcs19_build',
    :install_target => 'sandbox/tcs19_mingw',
    :patches => 'resources/patches/ruby193',
    :configure_options => [
      '--enable-shared',
      '--disable-install-doc'
    ],
    :files => [],
    :dependencies => [
      :ffi, :gdbm, :iconv, :openssl, :pdcurses, :yaml, :zlib, :tcl, :tk
    ],
      :excludes => [
        'libcharset1.dll'
    ],
  )

  if ENV['branch']
    RubyTCS.branch = ENV['branch']
  end
end
