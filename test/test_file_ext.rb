require_relative '../nix_utils/file_ext'

def fe_ck(label, expected, actual)
  if expected == actual
    puts "" + label + ":ok"
  else
    puts "" + label + ":FAIL expected=" + expected.inspect + " got=" + actual.inspect
  end
end

system("/bin/rm -f /tmp/sp_test_link /tmp/sp_test_sym2 /tmp/sp_test_hardlink")
system("/bin/ln -sf /tmp /tmp/sp_test_link")

# readlink
target = FileExt.readlink("/tmp/sp_test_link")
fe_ck "readlink", "/tmp", "" + target

# stat_str — check field count; exact values are system-specific
s = FileExt.stat_str("/tmp/sp_test_link")
fe_ck "stat_str field count", true, ("" + s).split.length >= 11

# lstat_str — should report symlink mode (first field starts with "12")
ls = FileExt.lstat_str("/tmp/sp_test_link")
fe_ck "lstat_str symlink mode", true, ("" + ls).split.first[0, 2] == "12"

# symlink creation
r = FileExt.symlink("/tmp", "/tmp/sp_test_sym2")
fe_ck "symlink rc", 0, r
fe_ck "symlink exists", true, File.symlink?("/tmp/sp_test_sym2")

# hard link — linking a symlink-to-directory fails on macOS (EPERM); rc non-zero expected
r2 = FileExt.link("/tmp/sp_test_link", "/tmp/sp_test_hardlink")
fe_ck "link dir rc nonzero", true, r2 != 0
fe_ck "link dir not created", false, File.exist?("/tmp/sp_test_hardlink")

system("/bin/rm -f /tmp/sp_test_link /tmp/sp_test_sym2 /tmp/sp_test_hardlink")
puts "done:ok"
