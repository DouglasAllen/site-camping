
# This module requires: #srcdir_root, #objdir_root, #relpath
module HookScriptAPI

  def get_config(key)
    @config[key]
  end

  alias config get_config

  # obsolete: use metaconfig to change configuration
  def set_config(key, val)
    @config[key] = val
  end

  #
  # srcdir/objdir (works only in the package directory)
  #

  def curr_srcdir
    "#{srcdir_root()}/#{relpath()}"
  end

  def curr_objdir
    "#{objdir_root()}/#{relpath()}"
  end

  def srcfile(path)
    "#{curr_srcdir()}/#{path}"
  end

  def srcexist?(path)
    File.exist?(srcfile(path))
  end

  def srcdirectory?(path)
    File.dir?(srcfile(path))
  end
  
  def srcfile?(path)
    File.file?(srcfile(path))
  end

  def srcentries(path = '.')
    Dir.open("#{curr_srcdir()}/#{path}") {|d|
      return d.to_a - %w(. ..)
    }
  end

  def srcfiles(path = '.')
    srcentries(path).select {|fname|
      File.file?(File.join(curr_srcdir(), path, fname))
    }
  end

  def srcdirectories(path = '.')
    srcentries(path).select {|fname|
      File.dir?(File.join(curr_srcdir(), path, fname))
    }
  end

end

