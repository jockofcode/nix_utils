PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))
NFT_TMP = "/tmp/nix_file_test"
EXT_O = File.join(PROJECT_ROOT, 'sp_file_ext.o')
system("mkdir -p '#{NFT_TMP}'")

$last_exit = 0

def ft_tool(name)
  File.join(PROJECT_ROOT, 'bin', "#{name}.rb")
end

def ft_rp(name, stdin_data, args = nil)
  sin = "#{NFT_TMP}/stdin"
  act = "#{NFT_TMP}/act"
  f = File.open(sin, 'wb'); f.write(stdin_data); f.close
  cmd = "spinel --link '#{EXT_O}' -E '#{ft_tool(name)}'"
  cmd = cmd + " #{args}" if args
  cmd = cmd + " < '#{sin}' > '#{act}' 2>/dev/null"
  system(cmd)
  f2 = File.open(act, 'rb'); r = f2.read; f2.close; r
rescue
  ""
end

def ft_rn(name, args = nil, stdin = nil)
  sin = "#{NFT_TMP}/stdin"
  act = "#{NFT_TMP}/act"
  cmd = "spinel --link '#{EXT_O}' -E '#{ft_tool(name)}'"
  cmd = cmd + " #{args}" if args
  if stdin
    f = File.open(sin, 'wb'); f.write(stdin); f.close
    cmd = cmd + " < '#{sin}' > '#{act}' 2>/dev/null"
  else
    cmd = cmd + " < /dev/null > '#{act}' 2>/dev/null"
  end
  system(cmd)
  f2 = File.open(act, 'rb'); r = f2.read; f2.close; r
rescue
  ""
end

def ft_ck(label, expected, actual)
  if expected == actual
    puts "#{label}:ok"
  else
    puts "#{label}:FAIL expected=#{expected.inspect} got=#{actual.inspect}"
  end
end

# ── basename / dirname ───────────────────────────────────────────────────────
ft_ck "basename path",   "ruby\n",     ft_rn("basename", "/usr/bin/ruby")
ft_ck "basename suffix", "libfoo\n",   ft_rn("basename", "/lib/libfoo.so .so")
ft_ck "basename -a",     "a\nb\n",     ft_rn("basename", "-a /x/a /y/b")
ft_ck "dirname path",    "/usr/bin\n", ft_rn("dirname", "/usr/bin/ruby")
ft_ck "dirname no dir",  ".\n",        ft_rn("dirname", "foo")
ft_ck "dirname root",    "/\n",        ft_rn("dirname", "/")

# ── pwd ─────────────────────────────────────────────────────────────────────
pwd_out = ft_rn("pwd").chomp
ft_ck "pwd is absolute", true, pwd_out.length > 0 && pwd_out[0] == "/"

# ── touch ───────────────────────────────────────────────────────────────────
touch_path = "#{NFT_TMP}/touch_test"
ft_rn("touch", "'#{touch_path}'")
ft_ck "touch creates file", true, File.exist?(touch_path)
File.delete(touch_path)

# ── stat ────────────────────────────────────────────────────────────────────
stat_path = "#{NFT_TMP}/stat_test"
File.write(stat_path, "hello\n")
stat_out = ft_rn("stat", "'#{stat_path}'")
ft_ck "stat shows file name", true, stat_out.include?(File.basename(stat_path))
ft_ck "stat shows size",      true, stat_out.include?("6")

# ── mkdir / rmdir ────────────────────────────────────────────────────────────
mkbase = "#{NFT_TMP}/mkdir_test"
ft_rn("mkdir", "'#{mkbase}'")
ft_ck "mkdir creates dir", true, File.directory?(mkbase)
ft_rn("mkdir", "-p '#{mkbase}/a/b/c'")
ft_ck "mkdir -p nested", true, File.directory?("#{mkbase}/a/b/c")
ft_rn("rmdir", "'#{mkbase}/a/b/c'")
ft_ck "rmdir removes dir", false, File.directory?("#{mkbase}/a/b/c")
system("rm -rf '#{mkbase}'")

# ── cp / mv / rm ────────────────────────────────────────────────────────────
cp_src = "#{NFT_TMP}/cp_src"; File.write(cp_src, "copy me\n")
cp_dst = "#{cp_src}.dst"
ft_rn("cp", "'#{cp_src}' '#{cp_dst}'")
ft_ck "cp copies file", "copy me\n", (File.read(cp_dst) rescue "")
ft_rn("rm", "'#{cp_dst}'")
ft_ck "rm removes file", false, File.exist?(cp_dst)

mv_src = "#{NFT_TMP}/mv_src"; File.write(mv_src, "move me\n")
mv_dst = "#{mv_src}.dst"
ft_rn("mv", "'#{mv_src}' '#{mv_dst}'")
ft_ck "mv moves file",    "move me\n", (File.read(mv_dst) rescue "")
ft_ck "mv removes source", false, File.exist?(mv_src)
File.delete(mv_dst) if File.exist?(mv_dst)
File.delete(cp_src) if File.exist?(cp_src)

# ── ln ──────────────────────────────────────────────────────────────────────
ln_target = "#{NFT_TMP}/ln_target"; File.write(ln_target, "link content\n")
ln_sym = "#{ln_target}.symlink"
ft_rn("ln", "-s '#{ln_target}' '#{ln_sym}'")
ft_ck "ln -s creates symlink",  true, File.symlink?(ln_sym)
ft_ck "ln -s target readable",  "link content\n", (File.read(ln_sym) rescue "")
File.delete(ln_sym) if File.exist?(ln_sym) || File.symlink?(ln_sym)

ln_hard = "#{ln_target}.hard"
ft_rn("ln", "'#{ln_target}' '#{ln_hard}'")
ft_ck "ln hard link",         true,            File.exist?(ln_hard)
ft_ck "ln hard same content", "link content\n",(File.read(ln_hard) rescue "")
File.delete(ln_hard) if File.exist?(ln_hard)
File.delete(ln_target) if File.exist?(ln_target)

# ── ls ──────────────────────────────────────────────────────────────────────
ls_dir = "#{NFT_TMP}/ls_test"
Dir.mkdir(ls_dir)
File.write("#{ls_dir}/alpha.txt", "a")
File.write("#{ls_dir}/beta.txt", "bb")
ls_out = ft_rn("ls", "'#{ls_dir}'")
ft_ck "ls lists files",      true, ls_out.include?("alpha.txt") && ls_out.include?("beta.txt")
ls_l = ft_rn("ls", "-l '#{ls_dir}'")
ft_ck "ls -l permissions",   true, ls_l.include?("-rw")
ft_ck "ls -l sizes",         true, ls_l.include?("1") && ls_l.include?("2")
ls_1 = ft_rn("ls", "-1 '#{ls_dir}'")
ft_ck "ls -1 one per line",  2, ls_1.lines.length
system("rm -rf '#{ls_dir}'")

# ── find ────────────────────────────────────────────────────────────────────
find_dir = "#{NFT_TMP}/find_test"
system("mkdir -p '#{find_dir}/sub'")
File.write("#{find_dir}/file.rb", "data\n")
File.write("#{find_dir}/sub/other.txt", "data\n")
find_rb = ft_rn("find", "'#{find_dir}' -name '*.rb'")
ft_ck "find -name matches",    true, find_rb.include?("file.rb")
find_d = ft_rn("find", "'#{find_dir}' -type d")
ft_ck "find -type d dirs",     true, find_d.include?("sub")
find_m = ft_rn("find", "'#{find_dir}' -maxdepth 1")
ft_ck "find -maxdepth 1",      true, !find_m.include?("other.txt")
find_e = ft_rn("find", "'#{find_dir}' -maxdepth 1 -name '*.rb' -exec echo {} \\;")
ft_ck "find -exec echo",       true, find_e.include?("file.rb")
system("rm -rf '#{find_dir}'")

# ── du ──────────────────────────────────────────────────────────────────────
du_dir = "#{NFT_TMP}/du_test"
Dir.mkdir(du_dir)
File.write("#{du_dir}/file", "hello\n")
du_out = ft_rn("du", "'#{du_dir}'")
ft_ck "du produces output", true, du_out.length > 0
du_s = ft_rn("du", "-s '#{du_dir}'")
ft_ck "du -s one line", 1, du_s.lines.length
du_h = ft_rn("du", "-h '#{du_dir}'")
ft_ck "du -h suffixes", true, du_h.match?(/[0-9]+[BKMGT]?/)
system("rm -rf '#{du_dir}'")

# ── split ───────────────────────────────────────────────────────────────────
split_dir = "#{NFT_TMP}/split_test"
Dir.mkdir(split_dir)
File.write("#{split_dir}/input", (1..10).map { |i| "#{i}\n" }.join)
ft_rn("split", "-l 3 '#{split_dir}/input' '#{split_dir}/out'")
file_count = Dir.glob("#{split_dir}/out*").length
ft_ck "split -l 3 creates 4 files", 4, file_count
reassembled = Dir.glob("#{split_dir}/out*").sort.map { |f| File.read(f) }.join
ft_ck "split reassembly matches", File.read("#{split_dir}/input"), reassembled
File.write("#{split_dir}/bytes", "abcdefghij")
ft_rn("split", "-b 3 '#{split_dir}/bytes' '#{split_dir}/bsplit'")
bc = Dir.glob("#{split_dir}/bsplit*").length
ft_ck "split -b 3 creates 4 files", 4, bc
system("rm -rf '#{split_dir}'")

# ── realpath ────────────────────────────────────────────────────────────────
rp_dir = "#{NFT_TMP}/rp_test"
Dir.mkdir(rp_dir)
rp_expected = `cd '#{rp_dir}' && pwd -P`.chomp
ft_ck "realpath existing dir", "#{rp_expected}\n", ft_rn("realpath", "'#{rp_dir}'")
rp_miss = ft_rn("realpath", "-m '#{rp_dir}/nonexistent'")
ft_ck "realpath -m missing", true, rp_miss.length > 0
_rp_ec = "#{NFT_TMP}/rp_ec"
system("spinel --link '#{EXT_O}' -E '#{ft_tool("realpath")}' -e '#{rp_dir}/nonexistent' > /dev/null 2>&1; echo $? > '#{_rp_ec}'")
ft_ck "realpath -e missing exit", true, File.read(_rp_ec).to_i != 0
system("rm -rf '#{rp_dir}'")

# ── readlink ────────────────────────────────────────────────────────────────
rl_target = "#{NFT_TMP}/rl_target"; File.write(rl_target, "target\n")
rl_link = "#{rl_target}.link"
system("ln -s '#{rl_target}' '#{rl_link}'")
ft_ck "readlink prints target", "#{rl_target}\n", ft_rn("readlink", "'#{rl_link}'")
File.delete(rl_link) if File.symlink?(rl_link)
File.delete(rl_target) if File.exist?(rl_target)

# ── mktemp ──────────────────────────────────────────────────────────────────
tf = ft_rn("mktemp").chomp
ft_ck "mktemp creates file", true, File.file?(tf)
File.delete(tf) if File.exist?(tf)

td = ft_rn("mktemp", "-d").chomp
ft_ck "mktemp -d creates dir", true, File.directory?(td)
system("rm -rf '#{td}'") if File.exist?(td)

tu = ft_rn("mktemp", "-u").chomp
ft_ck "mktemp -u no file", true, !File.exist?(tu)

tt = ft_rn("mktemp", "mytest.XXXXXXXX").chomp
ft_ck "mktemp template prefix", true, File.basename(tt).start_with?("mytest.")
File.delete(tt) if File.exist?(tt)

system("rm -rf '#{NFT_TMP}'")
