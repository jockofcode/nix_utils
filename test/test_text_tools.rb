PROJECT_ROOT = File.expand_path('..', File.dirname(__FILE__))
NTT_TMP = "/tmp/nix_text_test"
system("mkdir -p '#{NTT_TMP}'")

$last_exit = 0

def ttt_tool(name)
  File.join(PROJECT_ROOT, 'bin', "#{name}.rb")
end

def ttt_rp(name, stdin_data, args = nil)
  sin = "#{NTT_TMP}/stdin"
  act = "#{NTT_TMP}/act"
  f = File.open(sin, 'wb'); f.write(stdin_data); f.close
  cmd = "spinel -E '#{ttt_tool(name)}'"
  cmd = cmd + " #{args}" if args
  cmd = cmd + " < '#{sin}' > '#{act}' 2>/dev/null"
  system(cmd)
  f2 = File.open(act, 'rb'); r = f2.read; f2.close; r
rescue
  ""
end

def ttt_rn(name, args = nil, stdin = nil)
  sin = "#{NTT_TMP}/stdin"
  act = "#{NTT_TMP}/act"
  cmd = "spinel -E '#{ttt_tool(name)}'"
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

def ttt_ck(label, expected, actual)
  if expected == actual
    puts "#{label}:ok"
  else
    puts "#{label}:FAIL expected=#{expected.inspect} got=#{actual.inspect}"
  end
end

# ── tac ─────────────────────────────────────────────────────────────────────
ttt_ck "tac basic",             "c\nb\na\n",  ttt_rp("tac", "a\nb\nc\n")
ttt_ck "tac single line",       "a\n",        ttt_rp("tac", "a\n")
ttt_ck "tac custom separator",  "c,b,a,",     ttt_rp("tac", "a,b,c,", "-s,")
ttt_ck "tac before mode",       "c\nb\na",    ttt_rp("tac", "a\nb\nc", "-b")
ttt_ck "tac regex separator",   "cb22a1",     ttt_rp("tac", "a1b22c", "-r -s '[0-9]+'")
ttt_ck "tac regex before mode", "c22b1a",     ttt_rp("tac", "a1b22c", "-r -b -s '[0-9]+'")

# ── seq ─────────────────────────────────────────────────────────────────────
ttt_ck "seq LAST",           "1\n2\n3\n",       ttt_rn("seq", "3")
ttt_ck "seq FIRST LAST",     "3\n4\n5\n",       ttt_rn("seq", "3 5")
ttt_ck "seq FIRST INC LAST", "0\n2\n4\n",       ttt_rn("seq", "0 2 4")
ttt_ck "seq descending",     "5\n4\n3\n",       ttt_rn("seq", "5 -1 3")
ttt_ck "seq -s separator",   "1,2,3,4,5\n",     ttt_rn("seq", "-s, 1 5")
ttt_ck "seq -w equal width", "08\n09\n10\n",    ttt_rn("seq", "-w 8 10")
ttt_ck "seq float",          "1.0\n1.5\n2.0\n", ttt_rn("seq", "1.0 0.5 2.0")

# ── sort ────────────────────────────────────────────────────────────────────
ttt_ck "sort basic",               "apple\nbanana\ncherry\n",  ttt_rp("sort", "banana\ncherry\napple\n")
ttt_ck "sort -r reverse",          "cherry\nbanana\napple\n", ttt_rp("sort", "apple\nbanana\ncherry\n", "-r")
ttt_ck "sort -n numeric",          "1\n3\n10\n25\n",          ttt_rp("sort", "10\n3\n25\n1\n", "-n")
ttt_ck "sort -u unique",           "a\nb\nc\n",               ttt_rp("sort", "a\nb\na\nc\nb\n", "-u")
ttt_ck "sort -f case insensitive", "a\nApple\nb\n",           ttt_rp("sort", "Apple\nb\na\n", "-f")
ttt_ck "sort -k field",            "root:0\nuser:1000\n",     ttt_rp("sort", "user:1000\nroot:0\n", "-t: -k2n")

# ── uniq ────────────────────────────────────────────────────────────────────
ttt_ck "uniq basic",            "a\nb\nc\n",                        ttt_rp("uniq", "a\na\nb\nb\nc\n")
ttt_ck "uniq -c count",         "      2 a\n      1 b\n      3 c\n", ttt_rp("uniq", "a\na\nb\nc\nc\nc\n", "-c")
ttt_ck "uniq -d repeated only", "a\nc\n",                           ttt_rp("uniq", "a\na\nb\nc\nc\nc\n", "-d")
ttt_ck "uniq -u unique only",   "b\n",                              ttt_rp("uniq", "a\na\nb\nc\nc\n", "-u")
ttt_ck "uniq -i ignore case",   "a\nb\n",                           ttt_rp("uniq", "a\nA\nb\n", "-i")

# ── cut ─────────────────────────────────────────────────────────────────────
ttt_ck "cut -f fields tab",        "a\n1\n",              ttt_rp("cut", "a\tb\tc\n1\t2\t3\n", "-f1")
ttt_ck "cut -d: -f1,3",            "root:0\nuser:1000\n", ttt_rp("cut", "root:x:0:0\nuser:x:1000:1000\n", "-d: -f1,3")
ttt_ck "cut -c range",             "bcd\nhij\n",          ttt_rp("cut", "abcdef\nghijkl\n", "-c2-4")
ttt_ck "cut -c open end",          "cdef\nijkl\n",        ttt_rp("cut", "abcdef\nghijkl\n", "-c3-")
ttt_ck "cut -f complement",        "b\n2\n",              ttt_rp("cut", "a\tb\tc\n1\t2\t3\n", "-f1,3 --complement")
ttt_ck "cut -s suppress no-delim", "a:b\n",               ttt_rp("cut", "a:b\nnodeli\n", "-d: -f1,2 -s")

# ── tr ──────────────────────────────────────────────────────────────────────
ttt_ck "tr uppercase",            "HELLO WORLD\n", ttt_rp("tr", "hello world\n", "'a-z' 'A-Z'")
ttt_ck "tr -d delete",            "Hll Wrld\n",    ttt_rp("tr", "Hello World\n", "-d 'aeiouAEIOU'")
ttt_ck "tr -s squeeze",           "abc\n",         ttt_rp("tr", "aabbcc\n", "-s 'a-c'")
ttt_ck "tr -d -s delete squeeze", "bc\n",          ttt_rp("tr", "aabbc\n", "-ds 'a' 'b-c'")
ttt_ck "tr escape sequences",     "a b\n",         ttt_rp("tr", "a\tb\n", "'\\t' ' '")

# ── fold ────────────────────────────────────────────────────────────────────
ttt_ck "fold -w wrap",            "abcde\nfghij\n",  ttt_rp("fold", "abcdefghij\n", "-w5")
ttt_ck "fold -w -s break space",  "hello \nworld\n", ttt_rp("fold", "hello world\n", "-w7 -s")
ttt_ck "fold short no wrap",      "abc\n",           ttt_rp("fold", "abc\n", "-w10")
ttt_ck "fold -c tab as one char", "a\tb\n",          ttt_rp("fold", "a\tb\n", "-c -w8")
ttt_ck "fold default tab expands","a\t\nb\n",         ttt_rp("fold", "a\tb\n", "-w8")

# ── nl ──────────────────────────────────────────────────────────────────────
ttt_ck "nl default nonempty",
  "     1\tfoo\n       \n     2\tbar\n",
  ttt_rp("nl", "foo\n\nbar\n")
ttt_ck "nl -ba all lines",
  "     1\tfoo\n     2\t\n     3\tbar\n",
  ttt_rp("nl", "foo\n\nbar\n", "-ba")
ttt_ck "nl -v -i increment",
  "    10\ta\n    15\tb\n",
  ttt_rp("nl", "a\nb\n", "-v10 -i5")
ttt_ck "nl -nrz zero padded",
  "000001\tfoo\n",
  ttt_rp("nl", "foo\n", "-nrz -w6")
ttt_ck "nl sections",
  "\n     1\tHEAD\n\n     2\tbody\n\n     3\tFOOT\n",
  ttt_rp("nl", "\\:\\:\\:\nHEAD\n\\:\\:\nbody\n\\:\nFOOT\n", "-ha -ba -fa")
ttt_ck "nl -bp regex body",
  "     1\tfoo\n       bar\n     2\tfoobar\n",
  ttt_rp("nl", "foo\nbar\nfoobar\n", "-bpfoo")
ttt_ck "nl -p no page reset",
  "     1\tx\n\n     2\ty\n",
  ttt_rp("nl", "x\n\\:\\:\\:\ny\n", "-ba -ha -p")

# ── expand / unexpand ───────────────────────────────────────────────────────
ttt_ck "expand default tab=8", "a       b\n", ttt_rp("expand", "a\tb\n")
ttt_ck "expand -t4",           "a   b\n",     ttt_rp("expand", "a\tb\n", "-t 4")
ttt_ck "expand -t4 two tabs",  "a   b   c\n", ttt_rp("expand", "a\tb\tc\n", "-t 4")
ttt_ck "unexpand default",     "\ta\n",       ttt_rp("unexpand", "        a\n")
ttt_ck "unexpand -a mid-line", "\ta\tb\n",    ttt_rp("unexpand", "        a       b\n", "-a")

# ── paste ───────────────────────────────────────────────────────────────────
pa = "#{NTT_TMP}/paste_a"; File.write(pa, "a\nb\nc\n")
pb = "#{NTT_TMP}/paste_b"; File.write(pb, "1\n2\n3\n")
ttt_ck "paste parallel",    "a\t1\nb\t2\nc\t3\n", ttt_rn("paste", "'#{pa}' '#{pb}'")
ttt_ck "paste -d delimiter","a,1\nb,2\nc,3\n",    ttt_rn("paste", "-d, '#{pa}' '#{pb}'")
ttt_ck "paste -s serial",   "a\tb\tc\n",           ttt_rn("paste", "-s '#{pa}'")

system("rm -rf '#{NTT_TMP}'")
