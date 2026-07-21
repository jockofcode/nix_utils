PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))
NST_TMP = "/tmp/nix_stream_test"
system("mkdir -p '#{NST_TMP}'")

$last_exit = 0

def st_tool(name)
  File.join(PROJECT_ROOT, 'bin', "#{name}.rb")
end

def st_rp(name, stdin_data, args = nil)
  sin = "#{NST_TMP}/stdin"
  act = "#{NST_TMP}/act"
  f = File.open(sin, 'wb'); f.write(stdin_data); f.close
  cmd = "spinel -E '#{st_tool(name)}'"
  cmd = cmd + " #{args}" if args
  cmd = cmd + " < '#{sin}' > '#{act}' 2>/dev/null"
  system(cmd)
  f2 = File.open(act, 'rb'); r = f2.read; f2.close; r
rescue
  ""
end

def st_rn(name, args = nil, stdin = nil)
  sin = "#{NST_TMP}/stdin"
  act = "#{NST_TMP}/act"
  cmd = "spinel -E '#{st_tool(name)}'"
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

def st_ck(label, expected, actual)
  if expected == actual
    puts "#{label}:ok"
  else
    puts "#{label}:FAIL expected=#{expected.inspect} got=#{actual.inspect}"
  end
end

# ── cat -v / -A / -e / -t ───────────────────────────────────────────────────
st_ck "cat -v control char", "Hello^AWorld\n",    st_rp("cat", "Hello\x01World\n", "-v")
st_ck "cat -v high byte",    "M-^@\n",            st_rp("cat", "\x80\n", "-v")
st_ck "cat -A tab and end",  "^IHello^AWorld$\n", st_rp("cat", "\tHello\x01World\n", "-A")
st_ck "cat -e end only",     "hello$\n",          st_rp("cat", "hello\n", "-e")
st_ck "cat -t tab only",     "^Ihello\n",         st_rp("cat", "\thello\n", "-t")

# ── head ────────────────────────────────────────────────────────────────────
ten_lines = (1..10).map { |i| "#{i}\n" }.join
st_ck "head -n1K reads all lines", ten_lines, st_rp("head", ten_lines, "-n1K")
st_ck "head -c1K empty",           "",         st_rn("head", "-c1K /dev/null")

# ── tail ────────────────────────────────────────────────────────────────────
five = "a\nb\nc\nd\ne\n"
st_ck "tail -n3 last lines",  "c\nd\ne\n",   st_rp("tail", five, "-n3")
st_ck "tail -n+3 from line3", "c\nd\ne\n",   st_rp("tail", five, "-n+3")
st_ck "tail -c5 last bytes",  "\nd\ne\n",    st_rp("tail", five, "-c5")
st_ck "tail -c+6 from byte6", "\nd\ne\n",    st_rp("tail", five, "-c+6")
tail_act = st_rp("tail", "x\n", "-v -n1")
st_ck "tail -v header", true, tail_act.include?("==>")

# ── wc ──────────────────────────────────────────────────────────────────────
wca = "#{NST_TMP}/wc_a"; File.write(wca, "hello\nworld\n")
wcb = "#{NST_TMP}/wc_b"; File.write(wcb, "foo\n")
wclist = "#{NST_TMP}/wc_list"
system("printf '%s\\0%s\\0' '#{wca}' '#{wcb}' > '#{wclist}'")
st_ck "wc --files0-from",
  "      2 #{wca}\n      1 #{wcb}\n      3 total\n",
  st_rn("wc", "-l --files0-from='#{wclist}'")
st_ck "wc --total=always",
  "      2 #{wca}\n      2 total\n",
  st_rn("wc", "-l --total=always '#{wca}'")
st_ck "wc --total=never",
  "      2 #{wca}\n      1 #{wcb}\n",
  st_rn("wc", "-l --total=never '#{wca}' '#{wcb}'")
st_ck "wc --total=only",
  "      3 total\n",
  st_rn("wc", "-l --total=only '#{wca}' '#{wcb}'")

# ── grep ────────────────────────────────────────────────────────────────────
st_ck "grep basic match",        "hello\n",    st_rp("grep", "hello\nworld\n", "hello")
st_ck "grep no match",           "",           st_rp("grep", "hello\nworld\n", "xyz")
st_ck "grep -i case insensitive","Hello\n",    st_rp("grep", "Hello\nworld\n", "-i hello")
st_ck "grep -v invert",          "world\n",    st_rp("grep", "hello\nworld\n", "-v hello")
st_ck "grep -n line numbers",    "1:hello\n",  st_rp("grep", "hello\nworld\n", "-n hello")
st_ck "grep -c count",           "2\n",        st_rp("grep", "a\nb\na\nc\n", "-c a")
st_ck "grep -F fixed string",    "a.b\n",      st_rp("grep", "a.b\naXb\n", "-F a.b")
st_ck "grep -w word match",      "foo bar\n",  st_rp("grep", "foo bar\nfoobar\n", "-w foo")
st_ck "grep -x whole line",      "exact\n",    st_rp("grep", "exact\nexact match\n", "-x exact")
st_ck "grep -o only matching",   "ell\n",      st_rp("grep", "hello\nworld\n", "-o ell")
st_ck "grep -m max count",       "a\na\n",     st_rp("grep", "a\nb\na\na\n", "-m 2 a")
st_ck "grep regex",              "abc\nabc\n", st_rp("grep", "abc\ndef\nabc\n", "a.c")

# ── comm ────────────────────────────────────────────────────────────────────
comm1 = "#{NST_TMP}/comm1"; File.write(comm1, "a\nb\nc\n")
comm2 = "#{NST_TMP}/comm2"; File.write(comm2, "b\nc\nd\n")
st_ck "comm default",     "a\n\t\tb\n\t\tc\n\td\n", st_rn("comm", "'#{comm1}' '#{comm2}'")
st_ck "comm -12 common",  "b\nc\n",                  st_rn("comm", "-12 '#{comm1}' '#{comm2}'")
st_ck "comm -3 no common","a\n\td\n",                st_rn("comm", "-3 '#{comm1}' '#{comm2}'")

# ── strings ─────────────────────────────────────────────────────────────────
st_ck "strings basic",     "hello\n",    st_rp("strings", "\x01\x02hello\x03\x04")
st_ck "strings -n min len","abcde\n",    st_rp("strings", "abc\x01abcde\x02", "-n 5")
strings_f = "#{NST_TMP}/strings_f"
fw2 = File.open(strings_f, 'wb'); fw2.write("\x01\x02hello\x03"); fw2.close
st_ck "strings -f file name", "#{strings_f}: hello\n", st_rn("strings", "-f '#{strings_f}'")
st_ck "strings -N shorthand", "abcde\n",  st_rp("strings", "abc\x01abcde\x02", "-5")
strings_sep_in = "#{NST_TMP}/strings_sep_in"
system("printf 'aaaa\\0bbbb' > '#{strings_sep_in}'")
strings_sep_act = "#{NST_TMP}/strings_sep_act"
system("spinel -E '#{st_tool("strings")}' -s '|' < '#{strings_sep_in}' > '#{strings_sep_act}' 2>/dev/null")
st_ck "strings -s separator", "aaaa|bbbb|", File.read(strings_sep_act)

# ── echo ────────────────────────────────────────────────────────────────────
st_ck "echo basic",           "hello world\n", st_rn("echo", "hello world")
st_ck "echo -n no newline",   "hello",         st_rn("echo", "-n hello")
st_ck "echo -e escape tab",   "a\tb\n",        st_rn("echo", "-e 'a\\tb'")
st_ck "echo -e newline esc",  "a\nb\n",        st_rn("echo", "-e 'a\\nb'")

# ── yes ─────────────────────────────────────────────────────────────────────
yes_y = `spinel -E '#{st_tool("yes")}' 2>/dev/null | head -3`
st_ck "yes y lines", "y\ny\ny\n", yes_y
yes_no = `spinel -E '#{st_tool("yes")}' no 2>/dev/null | head -2`
st_ck "yes custom string", "no\nno\n", yes_no

# ── printf ──────────────────────────────────────────────────────────────────
st_ck "printf %d",      "42\n",          st_rn("printf", "'%d\\n' 42")
st_ck "printf %s",      "hello world\n", st_rn("printf", "'%s %s\\n' hello world")
st_ck "printf %f",      "3.140000\n",    st_rn("printf", "'%f\\n' 3.14")
st_ck "printf %x hex",  "ff\n",          st_rn("printf", "'%x\\n' 255")
st_ck "printf %o octal","17\n",          st_rn("printf", "'%o\\n' 15")
st_ck "printf width",   "  42\n",        st_rn("printf", "'%4d\\n' 42")
st_ck "printf repeat",  "1\n2\n3\n",     st_rn("printf", "'%d\\n' 1 2 3")

# ── fmt ─────────────────────────────────────────────────────────────────────
fmt_act = st_rp("fmt", "the quick brown fox jumped over the lazy dog the quick brown fox\n")
st_ck "fmt wraps at 75", true, fmt_act.lines.all? { |l| l.chomp.length <= 75 }
st_ck "fmt -w width",    "hello\nworld\n", st_rp("fmt", "hello world\n", "-w 6")
fmt_blank = st_rp("fmt", "a\n\nb\n")
st_ck "fmt blank lines", true, fmt_blank.lines.any? { |l| l.strip.empty? }

# ── join ────────────────────────────────────────────────────────────────────
join1 = "#{NST_TMP}/join1"; File.write(join1, "1 a\n2 b\n3 c\n")
join2 = "#{NST_TMP}/join2"; File.write(join2, "1 x\n2 y\n4 z\n")
st_ck "join default",      "1 a x\n2 b y\n",   st_rn("join", "'#{join1}' '#{join2}'")
st_ck "join -a1 unpaired", "1 a x\n2 b y\n3 c\n", st_rn("join", "-a 1 '#{join1}' '#{join2}'")

# ── od ──────────────────────────────────────────────────────────────────────
od_c = st_rp("od", "ABC\n", "-c")
st_ck "od -c dump",       true, od_c.include?("A")
od_def = st_rp("od", "\x01\x02")
st_ck "od default octal", true, od_def.length > 0
od_ax = st_rp("od", "ABC\n", "-A x -t x1")
st_ck "od -A x hex addr", true, od_ax[0] == "0"
od_an = st_rp("od", "AB\n", "-A n -a")
st_ck "od -a named chars", true, od_an.include?("nl")
od_big = st_rp("od", "\x01\x02", "-A n -t x2 --endian=big")
st_ck "od --endian big",    "0102", od_big.gsub(/[ \n]/, '')
od_lit = st_rp("od", "\x01\x02", "-A n -t x2 --endian=little")
st_ck "od --endian little", "0201", od_lit.gsub(/[ \n]/, '')

# ── hexdump ─────────────────────────────────────────────────────────────────
hd_c = st_rp("hexdump", "Hello\n", "-C")
st_ck "hexdump -C canonical", true, hd_c.include?("|Hello")
hd_def = st_rp("hexdump", "\x01\x02")
st_ck "hexdump default hex",  true, hd_def.length > 0
st_ck "hexdump -X one-byte",
  "0000000 41 42 43\n0000003\n",
  st_rp("hexdump", "ABC", "-X")
st_ck "hexdump -C not padded",
  "00000000  48 69                                             |Hi|\n00000002\n",
  st_rp("hexdump", "Hi", "-C")

# ── shuf ────────────────────────────────────────────────────────────────────
shuf_act = st_rp("shuf", "a\nb\nc\nd\n")
shuf_sorted = shuf_act.lines.map { |l| l.chomp }.sort.join(',') + ','
st_ck "shuf same lines", "a,b,c,d,", shuf_sorted
shuf_n = st_rp("shuf", "a\nb\nc\nd\n", "-n 2")
st_ck "shuf -n limits",  2, shuf_n.lines.length
shuf_e = st_rn("shuf", "-e x y z")
st_ck "shuf -e treats args", 3, shuf_e.lines.length

# ── column ──────────────────────────────────────────────────────────────────
col_ff = st_rp("column", "alpha\nbeta\ngamma\ndelta\n")
st_ck "column free-flow", true, col_ff.length > 0
col_t = st_rp("column", "a:b:c\n1:2:3\n", "-t -s:")
st_ck "column -t table", true, col_t.include?("a") && col_t.include?("b")
col_o = st_rp("column", "x:y:z\n1:2:3\n", "-t -s: -o'|'")
st_ck "column -o separator", true, col_o.include?("|")

# ── xargs ───────────────────────────────────────────────────────────────────
st_ck "xargs basic echo", "a b c\n",   st_rp("xargs", "a b c\n", "echo")
xargs_n = st_rp("xargs", "a b c\n", "-n 1 echo")
st_ck "xargs -n 1",   3, xargs_n.lines.length
xargs_i = st_rp("xargs", "world\n", "-I{} echo 'hello {}'")
st_ck "xargs -I replace", true, xargs_i.include?("hello world")
xargs_r = st_rp("xargs", "", "-r echo")
st_ck "xargs -r empty", true, xargs_r.length == 0

# ── sed ─────────────────────────────────────────────────────────────────────
st_ck "sed s/l/L/g",      "heLLo\n",  st_rp("sed", "hello\n", "'s/l/L/g'")
st_ck "sed -n p",         "hello\n",  st_rp("sed", "hello\n", "-n 'p'")
st_ck "sed 2,3p range",   "B\nC\n",   st_rp("sed", "A\nB\nC\n", "'2,3p' -n")
st_ck "sed 2d delete",    "A\nC\n",   st_rp("sed", "A\nB\nC\n", "'2d'")
st_ck "sed y transliterate","HELLO\n", st_rp("sed", "hello\n", "'y/helo/HELO/'")
sed_f = "#{NST_TMP}/sed_inplace"; File.write(sed_f, "foo\n")
st_rn("sed", "-i 's/foo/bar/' '#{sed_f}'")
st_ck "sed -i in-place", "bar\n", File.read(sed_f)

# ── tee ─────────────────────────────────────────────────────────────────────
tee_f = "#{NST_TMP}/tee.txt"
tee_out = st_rp("tee", "hello\n", "'#{tee_f}'")
st_ck "tee stdout", "hello\n", tee_out
st_ck "tee file",   "hello\n", (File.read(tee_f) rescue "")
st_rp("tee", "world\n", "-a '#{tee_f}'")
st_ck "tee append", "hello\nworld\n", (File.read(tee_f) rescue "")

system("rm -rf '#{NST_TMP}'")
