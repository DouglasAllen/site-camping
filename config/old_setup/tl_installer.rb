require './conf_table'

class ToplevelInstaller

  Version   = '3.4.0'
  Copyright = 'Copyright (c) 2000-2005 Minero Aoki'

  TASKS = [
    [ 'all',      'do config, setup, then install' ],
    [ 'config',   'saves your configurations' ],
    [ 'show',     'shows current configuration' ],
    [ 'setup',    'compiles ruby extentions and others' ],
    [ 'install',  'installs files' ],
    [ 'test',     'run all tests in test/' ],
    [ 'clean',    "does `make clean' for each extention" ],
    [ 'distclean',"does `make distclean' for each extention" ]
  ]

  def ToplevelInstaller.invoke
    config = ConfigTable.new(load_rbconfig())
    config.load_standard_entries
    config.load_multipackage_entries if multipackage?
    config.fixup
    klass = (multipackage?() ? ToplevelInstallerMulti : ToplevelInstaller)
    klass.new(File.dirname($0), config).invoke
  end

  def ToplevelInstaller.multipackage?
    File.dir?(File.dirname($0) + '/packages')
  end

  def ToplevelInstaller.load_rbconfig
    if arg = ARGV.detect {|arg| /\A--rbconfig=/ =~ arg }
      ARGV.delete(arg)
      load File.expand_path(arg.split(/=/, 2)[1])
      $".push 'rbconfig.rb'
    else
      require 'rbconfig'
    end
    RbConfig::CONFIG
  end

  def initialize(ardir_root, config)
    @ardir = File.expand_path(ardir_root)
    @config = config
    # cache
    @valid_task_re = nil
  end

  def config(key)
    @config[key]
  end

  def inspect
    "#<#{self.class} #{__id__()}>"
  end

  def invoke
    run_metaconfigs
    case task = parsearg_global()
    when nil, 'all'
      parsearg_config
      init_installers
      exec_config
      exec_setup
      exec_install
    else
      case task
      when 'config', 'test'
        ;
      when 'clean', 'distclean'
        @config.load_savefile if File.exist?(@config.savefile)
      else
        @config.load_savefile
      end
      __send__ "parsearg_#{task}"
      init_installers
      __send__ "exec_#{task}"
    end
  end
  
  def run_metaconfigs
    @config.load_script "#{@ardir}/metaconfig"
  end

  def init_installers
    @installer = Installer.new(@config, @ardir, File.expand_path('.'))
  end

  #
  # Hook Script API bases
  #

  def srcdir_root
    @ardir
  end

  def objdir_root
    '.'
  end

  def relpath
    '.'
  end

  #
  # Option Parsing
  #

  def parsearg_global
    while arg = ARGV.shift
      case arg
      when /\A\w+\z/
        setup_rb_error "invalid task: #{arg}" unless valid_task?(arg)
        return arg
      when '-q', '--quiet'
        @config.verbose = false
      when '--verbose'
        @config.verbose = true
      when '--help'
        print_usage $stdout
        exit 0
      when '--version'
        puts "#{File.basename($0)} version #{Version}"
        exit 0
      when '--copyright'
        puts Copyright
        exit 0
      else
        setup_rb_error "unknown global option '#{arg}'"
      end
    end
    nil
  end

  def valid_task?(t)
    valid_task_re() =~ t
  end

  def valid_task_re
    @valid_task_re ||= /\A(?:#{TASKS.map {|task,desc| task }.join('|')})\z/
  end

  def parsearg_no_options
    unless ARGV.empty?
      setup_rb_error "#{task}: unknown options: #{ARGV.join(' ')}"
    end
  end

  alias parsearg_show       parsearg_no_options
  alias parsearg_setup      parsearg_no_options
  alias parsearg_test       parsearg_no_options
  alias parsearg_clean      parsearg_no_options
  alias parsearg_distclean  parsearg_no_options

  def parsearg_config
    evalopt = []
    set = []
    @config.config_opt = []
    while i = ARGV.shift
      if /\A--?\z/ =~ i
        @config.config_opt = ARGV.dup
        break
      end
      name, value = *@config.parse_opt(i)
      if @config.value_config?(name)
        @config[name] = value
      else
        evalopt.push [name, value]
      end
      set.push name
    end
    evalopt.each do |name, value|
      @config.lookup(name).evaluate value, @config
    end
    # Check if configuration is valid
    set.each do |n|
      @config[n] if @config.value_config?(n)
    end
  end

  def parsearg_install
    @config.no_harm = false
    @config.install_prefix = ''
    while a = ARGV.shift
      case a
      when '--no-harm'
        @config.no_harm = true
      when /\A--prefix=/
        path = a.split(/=/, 2)[1]
        path = File.expand_path(path) unless path[0,1] == '/'
        @config.install_prefix = path
      else
        setup_rb_error "install: unknown option #{a}"
      end
    end
  end

  def print_usage(out)
    out.puts 'Typical Installation Procedure:'
    out.puts "  $ ruby #{File.basename $0} config"
    out.puts "  $ ruby #{File.basename $0} setup"
    out.puts "  # ruby #{File.basename $0} install (may require root privilege)"
    out.puts
    out.puts 'Detailed Usage:'
    out.puts "  ruby #{File.basename $0} <global option>"
    out.puts "  ruby #{File.basename $0} [<global options>] <task> [<task options>]"

    fmt = "  %-24s %s\n"
    out.puts
    out.puts 'Global options:'
    out.printf fmt, '-q,--quiet',   'suppress message outputs'
    out.printf fmt, '   --verbose', 'output messages verbosely'
    out.printf fmt, '   --help',    'print this message'
    out.printf fmt, '   --version', 'print version and quit'
    out.printf fmt, '   --copyright',  'print copyright and quit'
    out.puts
    out.puts 'Tasks:'
    TASKS.each do |name, desc|
      out.printf fmt, name, desc
    end

    fmt = "  %-24s %s [%s]\n"
    out.puts
    out.puts 'Options for CONFIG or ALL:'
    @config.each do |item|
      out.printf fmt, item.help_opt, item.description, item.help_default
    end
    out.printf fmt, '--rbconfig=path', 'rbconfig.rb to load',"running ruby's"
    out.puts
    out.puts 'Options for INSTALL:'
    out.printf fmt, '--no-harm', 'only display what to do if given', 'off'
    out.printf fmt, '--prefix=path',  'install path prefix', ''
    out.puts
  end

  #
  # Task Handlers
  #

  def exec_config
    @installer.exec_config
    @config.save   # must be final
  end

  def exec_setup
    @installer.exec_setup
  end

  def exec_install
    @installer.exec_install
  end

  def exec_test
    @installer.exec_test
  end

  def exec_show
    @config.each do |i|
      printf "%-20s %s\n", i.name, i.value if i.value?
    end
  end

  def exec_clean
    @installer.exec_clean
  end

  def exec_distclean
    @installer.exec_distclean
  end

end   # class ToplevelInstaller

