# proc_ext.rb -- native_func bindings for process operations missing in Spinel.
#
# COMPILATION
#   spinel nix_utils/tool.rb --link nix_utils/sp_proc_ext.c -o nix_utils/bin/tool

module ProcExt
  def self.native_func(*args); end

  # ProcExt.sethostname(name) -> Integer  (0 = ok, errno on failure)
  native_func :sethostname, [:string], :int, "sp_sethostname_c"

  # ProcExt.exec_shell(cmd) -> Integer  (errno on failure; replaces process on success)
  native_func :exec_shell, [:string], :int, "sp_exec_shell_c"

  # ---- CRuby fallbacks -------------------------------------------------------
  # Spinel: native_func takes priority; these are compiled but never called.
  # CRuby:  these are the real implementations.

  def self.sethostname(name)
    system("hostname " + name) ? 0 : 1
  end

  def self.exec_shell(cmd)
    system("" + cmd)
    0
  end
end
