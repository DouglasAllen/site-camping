
class ToplevelInstallerMulti < ToplevelInstaller

  include FileOperations

  def initialize(ardir_root, config)
    super
    @packages = directories_of("#{@ardir}/packages")
    raise 'no package exists' if @packages.empty?
    @root_installer = Installer.new(@config, @ardir, File.expand_path('.'))
  end

  def run_metaconfigs
    @config.load_script "#{@ardir}/metaconfig", self
    @packages.each do |name|
      @config.load_script "#{@ardir}/packages/#{name}/metaconfig"
    end
  end

  attr_reader :packages

  def packages=(list)
    raise 'package list is empty' if list.empty?
    list.each do |name|
      raise "directory packages/#{name} does not exist"\
              unless File.dir?("#{@ardir}/packages/#{name}")
    end
    @packages = list
  end

  def init_installers
    @installers = {}
    @packages.each do |pack|
      @installers[pack] = Installer.new(@config,
                                       "#{@ardir}/packages/#{pack}",
                                       "packages/#{pack}")
    end
    with    = extract_selection(config('with'))
    without = extract_selection(config('without'))
    @selected = @installers.keys.select {|name|
                  (with.empty? or with.include?(name)) \
                      and not without.include?(name)
                }
  end

  def extract_selection(list)
    a = list.split(/,/)
    a.each do |name|
      setup_rb_error "no such package: #{name}"  unless @installers.key?(name)
    end
    a
  end

  def print_usage(f)
    super
    f.puts 'Inluded packages:'
    f.puts '  ' + @packages.sort.join(' ')
    f.puts
  end

  #
  # Task Handlers
  #

  def exec_config
    run_hook 'pre-config'
    each_selected_installers {|inst| inst.exec_config }
    run_hook 'post-config'
    @config.save   # must be final
  end

  def exec_setup
    run_hook 'pre-setup'
    each_selected_installers {|inst| inst.exec_setup }
    run_hook 'post-setup'
  end

  def exec_install
    run_hook 'pre-install'
    each_selected_installers {|inst| inst.exec_install }
    run_hook 'post-install'
  end

  def exec_test
    run_hook 'pre-test'
    each_selected_installers {|inst| inst.exec_test }
    run_hook 'post-test'
  end

  def exec_clean
    rm_f @config.savefile
    run_hook 'pre-clean'
    each_selected_installers {|inst| inst.exec_clean }
    run_hook 'post-clean'
  end

  def exec_distclean
    rm_f @config.savefile
    run_hook 'pre-distclean'
    each_selected_installers {|inst| inst.exec_distclean }
    run_hook 'post-distclean'
  end

  #
  # lib
  #

  def each_selected_installers
    Dir.mkdir 'packages' unless File.dir?('packages')
    @selected.each do |pack|
      $stderr.puts "Processing the package `#{pack}' ..." if verbose?
      Dir.mkdir "packages/#{pack}" unless File.dir?("packages/#{pack}")
      Dir.chdir "packages/#{pack}"
      yield @installers[pack]
      Dir.chdir '../..'
    end
  end

  def run_hook(id)
    @root_installer.run_hook id
  end

  # module FileOperations requires this
  def verbose?
    @config.verbose?
  end

  # module FileOperations requires this
  def no_harm?
    @config.no_harm?
  end

end   # class ToplevelInstallerMulti

