PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))
SYT_TMP = "/tmp/nix_sys_#{$$}"
system("mkdir -p '#{SYT_TMP}'")

$last_exit = 0

def sy_tool(name)
  File.join(PROJECT_ROOT, 'bin', "#{name}.rb")
end

def sy_rp(name, stdin_data, args = nil)
  sin = "#{SYT_TMP}/stdin"
  act = "#{SYT_TMP}/act"
  f = File.open(sin, 'wb'); f.write(stdin_data); f.close
  cmd = "ruby '#{sy_tool(name)}'"
  cmd = cmd + " #{args}" if args
  cmd = cmd + " < '#{sin}' > '#{act}' 2>/dev/null"
  system(cmd)
  $last_exit = $? ? $?.exitstatus : -1
  f2 = File.open(act, 'rb'); r = f2.read; f2.close; r
rescue
  ""
end

def sy_rn(name, args = nil, stdin = nil)
  sin = "#{SYT_TMP}/stdin"
  act = "#{SYT_TMP}/act"
  cmd = "ruby '#{sy_tool(name)}'"
  cmd = cmd + " #{args}" if args
  if stdin
    f = File.open(sin, 'wb'); f.write(stdin); f.close
    cmd = cmd + " < '#{sin}' > '#{act}' 2>/dev/null"
  else
    cmd = cmd + " < /dev/null > '#{act}' 2>/dev/null"
  end
  system(cmd)
  $last_exit = $? ? $?.exitstatus : -1
  f2 = File.open(act, 'rb'); r = f2.read; f2.close; r
rescue
  ""
end

def sy_ck(label, expected, actual)
  if expected == actual
    puts "#{label}:ok"
  else
    puts "#{label}:FAIL expected=#{expected.inspect} got=#{actual.inspect}"
  end
end

# ── whoami ──────────────────────────────────────────────────────────────────
whoami_out = sy_rn("whoami").chomp
sy_ck "whoami non-empty", true, whoami_out.length > 0

# ── hostname ────────────────────────────────────────────────────────────────
hostname_out = sy_rn("hostname").chomp
sy_ck "hostname non-empty", true, hostname_out.length > 0

# ── uname ───────────────────────────────────────────────────────────────────
uname_out = sy_rn("uname").chomp
sy_ck "uname non-empty", true, uname_out.length > 0
uname_a = sy_rn("uname", "-a")
sy_ck "uname -a multiple words", true, uname_a.split.length >= 3

# ── env ─────────────────────────────────────────────────────────────────────
env_out = sy_rn("env")
sy_ck "env lists variables", true, env_out.include?("=")
sy_ck "env -i with var", "FOO=bar\n", sy_rn("env", "-i FOO=bar")

# ── id ──────────────────────────────────────────────────────────────────────
id_out = sy_rn("id")
sy_ck "id contains uid", true, id_out.include?("uid=")
id_u_expected = `id -u`.chomp + "\n"
sy_ck "id -u numeric", id_u_expected, sy_rn("id", "-u")

# ── logname ─────────────────────────────────────────────────────────────────
logname_out = sy_rn("logname").chomp
sy_ck "logname non-empty", true, logname_out.length > 0
logname_expected = (ENV["LOGNAME"] || ENV["USER"] || "").chomp + "\n"
sy_ck "logname matches USER", logname_expected, sy_rn("logname")

# ── printenv ────────────────────────────────────────────────────────────────
pe_out = sy_rn("printenv")
sy_ck "printenv lists vars",  true, pe_out.include?("=")
sy_ck "printenv has HOME",    true, pe_out.include?("HOME=")
home_val = (ENV["HOME"] || "").chomp
sy_ck "printenv HOME value",  "#{home_val}\n", sy_rn("printenv", "HOME")
system("ruby '#{sy_tool("printenv")}' DEFINITELY_NOT_SET_VAR_XYZ123 > /dev/null 2>&1")
sy_ck "printenv missing exit 1", true, ($? ? $?.exitstatus == 1 : false)

# ── nproc ───────────────────────────────────────────────────────────────────
nproc_out = sy_rn("nproc").chomp.to_i
sy_ck "nproc positive integer", true, nproc_out >= 1
nproc_all = sy_rn("nproc", "--all").chomp.to_i
sy_ck "nproc --all positive",   true, nproc_all >= 1
nproc_ign = sy_rn("nproc", "--ignore=9999").chomp
sy_ck "nproc --ignore=9999 is 1", "1", nproc_ign

# ── sleep ───────────────────────────────────────────────────────────────────
t0 = Time.now
sy_rn("sleep", "0.1")
elapsed = Time.now - t0
sy_ck "sleep duration", true, elapsed >= 0.05

# ── true / false ────────────────────────────────────────────────────────────
system("ruby '#{sy_tool("true")}' > /dev/null 2>&1")
sy_ck "true exit 0", 0, ($? ? $?.exitstatus : -1)
system("ruby '#{sy_tool("false")}' > /dev/null 2>&1")
sy_ck "false exit 1", 1, ($? ? $?.exitstatus : -1)

# ── tsort ───────────────────────────────────────────────────────────────────
sy_ck "tsort basic DAG", "a\nb\nc\n", sy_rp("tsort", "a b\nb c\na c\n")
tsort_loop = sy_rp("tsort", "a a\n")
sy_ck "tsort self-loop", true, tsort_loop.length > 0

# ── factor ──────────────────────────────────────────────────────────────────
sy_ck "factor 12",          "12: 2 2 3\n", sy_rn("factor", "12")
sy_ck "factor 1",           "1: \n",       sy_rn("factor", "1")
sy_ck "factor 2 prime",     "2: 2\n",      sy_rn("factor", "2")
sy_ck "factor --exponents", "12: 2^2 3\n", sy_rn("factor", "-h 12")
factor_97 = sy_rn("factor", "97")
sy_ck "factor 97 prime", true, factor_97.include?("97: 97")
sy_ck "factor from stdin", "7: 7\n", sy_rp("factor", "7\n")

# ── date ────────────────────────────────────────────────────────────────────
year_out = sy_rn("date", "+%Y").chomp.to_i
sy_ck "date +%Y current year", true, year_out >= 2024
utc_tz = sy_rn("date", "--utc +%Z").chomp
sy_ck "date --utc +%Z is UTC", true, utc_tz == "UTC"
ref_year = sy_rn("date", "-r '#{SYT_TMP}' +%Y").chomp.to_i
sy_ck "date -r FILE year", true, ref_year >= 2020
iso_out = sy_rn("date", "-I").chomp
sy_ck "date -I ISO date", true, iso_out.match?(/\A[0-9]{4}-[0-9]{2}-[0-9]{2}\z/)

# ── base64 ──────────────────────────────────────────────────────────────────
encoded = sy_rp("base64", "hello world\n").chomp
decoded = sy_rn("base64", "-d", "#{encoded}\n")
sy_ck "base64 round-trip", "hello world\n", decoded
b64_wrap = sy_rp("base64", "A" * 64 + "\n", "-w 40")
first_line = b64_wrap.lines.first.to_s.chomp
sy_ck "base64 -w wrap", true, first_line.length <= 40

# ── sha256sum ────────────────────────────────────────────────────────────────
empty_sha = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
tf_empty = "#{SYT_TMP}/sha256_empty"; File.write(tf_empty, "")
sha_out = sy_rn("sha256sum", "'#{tf_empty}'")
sy_ck "sha256sum empty file", true, sha_out.include?(empty_sha)
sha_check = "#{SYT_TMP}/sha256_check"; File.write(sha_check, sha_out)
verify_out = sy_rn("sha256sum", "-c '#{sha_check}'")
sy_ck "sha256sum -c OK", true, verify_out.include?("OK")
sha_bad = "#{SYT_TMP}/sha256_bad"
File.write(sha_bad, "0000000000000000000000000000000000000000000000000000000000000000  #{tf_empty}\n")
system("ruby '#{sy_tool("sha256sum")}' -c '#{sha_bad}' > /dev/null 2>&1")
sy_ck "sha256sum -c FAIL exit", true, ($? ? $?.exitstatus != 0 : false)

# ── md5sum ──────────────────────────────────────────────────────────────────
empty_md5 = "d41d8cd98f00b204e9800998ecf8427e"
tf_md5 = "#{SYT_TMP}/md5_empty"; File.write(tf_md5, "")
md5_out = sy_rn("md5sum", "'#{tf_md5}'")
sy_ck "md5sum empty file", true, md5_out.include?(empty_md5)

# ── cksum ───────────────────────────────────────────────────────────────────
tf_ck_f = "#{SYT_TMP}/cksum_test"; File.write(tf_ck_f, "hello\n")
ck_out = sy_rn("cksum", "'#{tf_ck_f}'")
sy_ck "cksum produces output", true, ck_out.length > 0
cksum_hash = sy_rn("cksum", "-a md5 '#{tf_ck_f}'").split.first.to_s
md5_hash   = sy_rn("md5sum", "'#{tf_ck_f}'").split.first.to_s
sy_ck "cksum -a md5 matches md5sum", md5_hash, cksum_hash

# ── numfmt ──────────────────────────────────────────────────────────────────
sy_ck "numfmt 1000 to si", "1.0k\n",  sy_rp("numfmt", "1000\n", "--to=si")
sy_ck "numfmt 1K from iec","1024\n",  sy_rp("numfmt", "1K\n",   "--from=iec")
sy_ck "numfmt 1k from si", "1000\n",  sy_rp("numfmt", "1k\n",   "--from=si")

system("rm -rf '#{SYT_TMP}'")
