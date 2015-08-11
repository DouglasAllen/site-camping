
class Installer

  FILETYPES = %w( bin lib ext data conf man )

  include FileOperations
  include HookScriptAPI

  def initialize(config, srcroot, objroot)
    @config = config
    @srcdir = File.expand_path(srcroot)
    @objdir = File.expand_path(objroot)
    @currdir = '.'
  end

  def inspect
    "#<#{self.class} #{File.basename(@srcdir)}>"
  end

  #
  # Hook Script API base methods
  #

  def srcdir_root
    @srcdir
  end

  def objdir_root
    @objdir
  end

  def relpath
    @currdir
  end

  #
  # Config Access
  #

  # module FileOperations requires this
  def verbose?
    @config.verbose?
  end

  # module FileOperations requires this
  def no_harm?
    @config.no_harm?
  end

  def verbose_off
    begin
      save, @config.verbose = @config.verbose?, false
      yield
    ensure
      @config.verbose = save
    end
  end

  #
  # TASK config
  #

  def exec_config
    exec_task_traverse 'config'
  end

  def config_dir_bin(rel)
  end

  def config_dir_lib(rel)
  end

  def config_dir_man(rel)
  end

  def config_dir_ext(rel)
    extconf if extdir?(curr_srcdir())
  end

  def extconf
    ruby "#{curr_srcdir()}/extconf.rb", *@config.config_opt
  end

  def config_dir_data(rel)
  end

  def config_dir_conf(rel)
  end

  #
  # TASK setup
  #

  def exec_setup
    exec_task_traverse 'setup'
  end

  def setup_dir_bin(rel)
    files_of(curr_srcdir()).each do |fname|
      adjust_shebang "#{curr_srcdir()}/#{fname}"
    end
  end

  def adjust_shebang(path)
    return if no_harm?
    tmpfile = File.basename(path) + '.tmp'
    begin
      File.open(path, 'rb') {|r|
        first = r.gets
        return unless File.basename(first.sub(/\A\#!/, '').split[0].to_s) == 'ruby'
        $stderr.puts "adjusting shebang: #{File.basename(path)}" if verbose?
        File.open(tmpfile, 'wb') {|w|
          w.print first.sub(/\A\#!\s*\S+/, '#! ' + config('rubypath'))
          w.write r.read
        }
      }
      move_file tmpfile, File.basename(path)
    ensure
      File.unlink tmpfile if File.exist?(tmpfile)
    end
  end

  def setup_dir_lib(rel)
  end

  def setup_dir_man(rel)
  end

  def setup_dir_ext(rel)
    make if extdir?(curr_srcdir())
  end

  def setup_dir_data(rel)
  end

  def setup_dir_conf(rel)
  end

  #
  # TASK install
  #

  def exec_install
    rm_f 'InstalledFiles'
    exec_task_traverse 'install'
  end

  def install_dir_bin(rel)
    install_files targetfiles(), "#{config('bindir')}/#{rel}", 0755
  end

  def install_dir_lib(rel)
    install_files rubyscripts(), "#{config('rbdir')}/#{rel}", 0644
  end

  def install_dir_ext(rel)
    return unless extdir?(curr_srcdir())
    install_files rubyextentions('.'),
                  "#{config('sodir')}/#{File.dirname(rel)}",
                  0555
  end

  def install_dir_data(rel)
    install_files targetfiles(), "#{config('datadir')}/#{rel}", 0644
  end

  def install_dir_conf(rel)
    # FIXME: should not remove current config files
    # (rename previous file to .old/.org)
    install_files targetfiles(), "#{config('sysconfdir')}/#{rel}", 0644
  end

  def install_dir_man(rel)
    install_files targetfiles(), "#{config('mandir')}/#{rel}", 0644
  end

  def install_files(list, dest, mode)
    mkdir_p dest, @config.install_prefix
    list.each do |fname|
      install fname, dest, mode, @config.install_prefix
    end
  end

  def rubyscripts
    glob_select(@config.libsrc_pattern, targetfiles())
  end

  def rubyextentions(dir)
    ents = glob_select("*.#{@config.dllext}", targetfiles())
    if ents.empty?
      setup_rb_error "no ruby extention exists: 'ruby #{$0} setup' first"
    end
    ents
  end

  def targetfiles
    mapdir(existfiles() - hookfiles())
  end

  def mapdir(ents)
    ents.map {|ent|
      if File.exist?(ent)
      then ent                         # objdir
      else "#{curr_srcdir()}/#{ent}"   # srcdir
      end
    }
  end

  # picked up many entries from cvs-1.11.1/src/ignore.c
  JUNK_FILES = %w( 
    core RCSLOG tags TAGS .make.state
    .nse_depinfo #* .#* cvslog.* ,* .del-* *.olb
    *~ *.old *.bak *.BAK *.orig *.rej _$* *$

    *.org *.in .*
  )

  def existfiles
    glob_reject(JUNK_FILES, (files_of(curr_srcdir()) | files_of('.')))
  end

  def hookfiles
    %w( pre-%s post-%s pre-%s.rb post-%s.rb ).map {|fmt|
      %w( config setup install clean ).map {|t| sprintf(fmt, t) }
    }.flatten
  end

  def glob_select(pat, ents)
    re = globs2re([pat])
    ents.select {|ent| re =~ ent }
  end

  def glob_reject(pats, ents)
    re = globs2re(pats)
    ents.reject {|ent| re =~ ent }
  end

  GLOB2REGEX = {
    '.' => '\.',
    '$' => '\$',
    '#' => '\#',
    '*' => '.*'
  }

  def globs2re(pats)
    /\A(?:#{
      pats.map {|pat| pat.gsub(/[\.\$\#\*]/) {|ch| GLOB2REGEX[ch] } }.join('|')
    })\z/
  end

  #
  # TASK test
  #

  TESTDIR = 'test'

  def exec_test
    unless File.directory?('test')
      $stderr.puts 'no test in this package' if verbose?
      return
    end
    $stderr.puts 'Running tests...' if verbose?
    require 'test/unit'
    runner = Test::Unit::AutoRunner.new(true)
    runner.to_run << TESTDIR
    runner.run
  end

  #
  # TASK clean
  #

  def exec_clean
    exec_task_traverse 'clean'
    rm_f @config.savefile
    rm_f 'InstalledFiles'
  end

  def clean_dir_bin(rel)
  end

  def clean_dir_lib(rel)
  end

  def clean_dir_ext(rel)
    return unless extdir?(curr_srcdir())
    make 'clean' if File.file?('Makefile')
  end

  def clean_dir_data(rel)
  end

  def clean_dir_conf(rel)
  end

  #
  # TASK distclean
  #

  def exec_distclean
    exec_task_traverse 'distclean'
    rm_f @config.savefile
    rm_f 'InstalledFiles'
  end

  def distclean_dir_bin(rel)
  end

  def distclean_dir_lib(rel)
  end

  def distclean_dir_ext(rel)
    return unless extdir?(curr_srcdir())
    make 'distclean' if File.file?('Makefile')
  end

  def distclean_dir_data(rel)
  end

  def distclean_dir_conf(rel)
  end

  #
  # lib
  #

  def exec_task_traverse(task)
    run_hook "pre-#{task}"
    FILETYPES.each do |type|
      if config('without-ext') == 'yes' and type == 'ext'
        $stderr.puts 'skipping ext/* by user option' if verbose?
        next
      end
      traverse task, type, "#{task}_dir_#{type}"
    end
    run_hook "post-#{task}"
  end

  def traverse(task, rel, mid)
    dive_into(rel) {
      run_hook "pre-#{task}"
      __send__ mid, rel.sub(%r[\A.*?(?:/|\z)], '')
      directories_of(curr_srcdir()).each do |d|
        traverse task, "#{rel}/#{d}", mid
      end
      run_hook "post-#{task}"
    }
  end

  def dive_into(rel)
    return unless File.dir?("#{@srcdir}/#{rel}")

    dir = File.basename(rel)
    Dir.mkdir dir unless File.dir?(dir)
    prevdir = Dir.pwd
    Dir.chdir dir
    $stderr.puts '---> ' + rel if verbose?
    @currdir = rel
    yield
    Dir.chdir prevdir
    $stderr.puts '<--- ' + rel if verbose?
    @currdir = File.dirname(rel)
  end

  def run_hook(id)
    path = [ "#{curr_srcdir()}/#{id}",
             "#{curr_srcdir()}/#{id}.rb" ].detect {|cand| File.file?(cand) }
    return unless path
    begin
      instance_eval File.read(path), path, 1
    rescue
      raise if $DEBUG
      setup_rb_error "hook #{path} failed:\n" + $!.message
    end
  end

end   # class Installer



if $0 == __FILE__
  begin
    ToplevelInstaller.invoke
  rescue SetupError
    raise if $DEBUG
    $stderr.puts $!.message
    $stderr.puts "Try 'ruby #{$0} --help' for detailed usage."
    exit 1
  end
end
