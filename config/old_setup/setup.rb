
require './tl_installer'

class SetupError < StandardError; end

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
