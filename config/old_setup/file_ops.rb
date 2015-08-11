
# This module requires: #verbose?, #no_harm?
module FileOperations

  def mkdir_p(dirname, prefix = nil)
    dirname = prefix + File.expand_path(dirname) if prefix
    $stderr.puts "mkdir -p #{dirname}" if verbose?
    return if no_harm?

    # Does not check '/', it's too abnormal.
    dirs = File.expand_path(dirname).split(%r<(?=/)>)
    if /\A[a-z]:\z/i =~ dirs[0]
      disk = dirs.shift
      dirs[0] = disk + dirs[0]
    end
    dirs.each_index do |idx|
      path = dirs[0..idx].join('')
      Dir.mkdir path unless File.dir?(path)
    end
  end

  def rm_f(path)
    $stderr.puts "rm -f #{path}" if verbose?
    return if no_harm?
    force_remove_file path
  end

  def rm_rf(path)
    $stderr.puts "rm -rf #{path}" if verbose?
    return if no_harm?
    remove_tree path
  end

  def remove_tree(path)
    if File.symlink?(path)
      remove_file path
    elsif File.dir?(path)
      remove_tree0 path
    else
      force_remove_file path
    end
  end

  def remove_tree0(path)
    Dir.foreach(path) do |ent|
      next if ent == '.'
      next if ent == '..'
      entpath = "#{path}/#{ent}"
      if File.symlink?(entpath)
        remove_file entpath
      elsif File.dir?(entpath)
        remove_tree0 entpath
      else
        force_remove_file entpath
      end
    end
    begin
      Dir.rmdir path
    rescue Errno::ENOTEMPTY
      # directory may not be empty
    end
  end

  def move_file(src, dest)
    force_remove_file dest
    begin
      File.rename src, dest
    rescue
      File.open(dest, 'wb') {|f|
        f.write File.binread(src)
      }
      File.chmod File.stat(src).mode, dest
      File.unlink src
    end
  end

  def force_remove_file(path)
    begin
      remove_file path
    rescue
    end
  end

  def remove_file(path)
    File.chmod 0777, path
    File.unlink path
  end

  def install(from, dest, mode, prefix = nil)
    $stderr.puts "install #{from} #{dest}" if verbose?
    return if no_harm?

    realdest = prefix ? prefix + File.expand_path(dest) : dest
    realdest = File.join(realdest, File.basename(from)) if File.dir?(realdest)
    str = File.binread(from)
    if diff?(str, realdest)
      verbose_off {
        rm_f realdest if File.exist?(realdest)
      }
      File.open(realdest, 'wb') {|f|
        f.write str
      }
      File.chmod mode, realdest

      File.open("#{objdir_root()}/InstalledFiles", 'a') {|f|
        if prefix
          f.puts realdest.sub(prefix, '')
        else
          f.puts realdest
        end
      }
    end
  end

  def diff?(new_content, path)
    return true unless File.exist?(path)
    new_content != File.binread(path)
  end

  def command(*args)
    $stderr.puts args.join(' ') if verbose?
    system(*args) or raise RuntimeError,
        "system(#{args.map{|a| a.inspect }.join(' ')}) failed"
  end

  def ruby(*args)
    command config('rubyprog'), *args
  end
  
  def make(task = nil)
    command(*[config('makeprog'), task].compact)
  end

  def extdir?(dir)
    File.exist?("#{dir}/MANIFEST") or File.exist?("#{dir}/extconf.rb")
  end

  def files_of(dir)
    Dir.open(dir) {|d|
      return d.select {|ent| File.file?("#{dir}/#{ent}") }
    }
  end

  DIR_REJECT = %w( . .. CVS SCCS RCS CVS.adm .svn )

  def directories_of(dir)
    Dir.open(dir) {|d|
      return d.select {|ent| File.dir?("#{dir}/#{ent}") } - DIR_REJECT
    }
  end

end

