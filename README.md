# nix_utils

A collection of common command-line tools rebuilt in
[Spinel](https://github.com/matz/spinel) — a compiled Ruby language. Each
tool works the same way as the classic Unix versions you already know, but
runs as a fast native binary produced by the Spinel compiler.

## What is this?

If you have ever typed `ls`, `grep`, `cat`, or `sort` in a terminal, you have
used tools like these. This project rebuilds 71 of them in Spinel so you can
study how they work, learn Spinel by reading real programs, or use them on
systems where the usual tools are not available.

## What tools are included?

| Tool | What it does |
|------|-------------|
| base64 | Convert files to safe text and back |
| basename | Get just the file name from a full path |
| cat | Print files to the screen |
| cksum | Create a checksum fingerprint for a file |
| column | Line up text into neat columns |
| comm | Compare two sorted files |
| cp | Copy files and directories |
| cut | Pull out selected columns from each line |
| date | Show the current date and time |
| dirname | Get the folder part of a file path |
| du | Find out how much disk space files are using |
| echo | Print words to the screen |
| env | Show environment variables |
| expand | Change tab characters into spaces |
| factor | Break a number into its prime factors |
| false | Do nothing and report failure |
| find | Search for files and folders |
| fmt | Reformat text paragraphs to a target width |
| fold | Wrap long lines to fit a certain width |
| grep | Search for lines that match a pattern |
| head | Show the first few lines of a file |
| hexdump | Show the raw bytes of a file in hex |
| hostname | Show the name of this computer |
| id | Show who you are logged in as |
| join | Combine two files by matching a shared field |
| ln | Create a link (shortcut) to a file |
| logname | Print your login name |
| ls | List files and folders in a directory |
| md5sum | Calculate or check MD5 fingerprints |
| mkdir | Create a new folder |
| mktemp | Create a temporary file with a unique name |
| mv | Move or rename a file |
| nl | Add line numbers to a file |
| nproc | Print how many processor cores are available |
| numfmt | Convert numbers to and from human-readable form |
| od | Dump file contents in octal or other formats |
| paste | Combine lines from multiple files side by side |
| printenv | Print the value of environment variables |
| printf | Format and print text with precise control |
| pwd | Print the current working directory |
| readlink | Show where a symbolic link points |
| realpath | Print the full, real path of a file |
| rm | Delete files and directories |
| rmdir | Remove an empty directory |
| sed | Find and replace text in a stream |
| seq | Print a sequence of numbers |
| sha1sum | Calculate or check SHA-1 fingerprints |
| sha224sum | Calculate or check SHA-224 fingerprints |
| sha256sum | Calculate or check SHA-256 fingerprints |
| sha384sum | Calculate or check SHA-384 fingerprints |
| sha512sum | Calculate or check SHA-512 fingerprints |
| shuf | Randomly shuffle lines |
| sleep | Pause for a set amount of time |
| sort | Arrange lines in order |
| split | Chop a big file into smaller pieces |
| stat | Show detailed information about a file |
| strings | Find readable text hidden inside any file |
| tac | Print a file in reverse order |
| tail | Show the last few lines of a file |
| tee | Send output to both the screen and a file |
| touch | Update a file's timestamp or create an empty file |
| tr | Translate or delete characters |
| true | Do nothing and report success |
| tsort | Sort a list where some items must come before others |
| uname | Print information about the operating system |
| unexpand | Convert spaces back into tab characters |
| uniq | Remove or report duplicate lines |
| wc | Count lines, words, and characters in a file |
| whoami | Print your current username |
| xargs | Build and run commands using a list of items |
| yes | Repeatedly print the same text over and over |

## Install Spinel

With `asdf`:

```bash
asdf plugin add spinel https://github.com/jockofcode/asdf-spinel
asdf install spinel master
asdf set -u spinel master   # make it the default (~/.tool-versions)
```

Or build it from source:

```bash
git clone https://github.com/matz/spinel.git
cd spinel
make
export PATH="$PWD/bin:$PATH"
cd -
```

## How to build

You need the [Spinel compiler](https://github.com/matz/spinel) installed.
Building the whole repo produces `bin/spin` alongside the compiler.

Build a single tool:

```sh
spin build bin/cat.rb
```

Run a tool without building first:

```sh
spin run bin/cat.rb -- myfile.txt
```

Build all tools:

```sh
spin build
```

Compiled binaries land in `build/bin/`. Install them to `~/.local/bin` so
you can use them anywhere:

```sh
spin install
```

## Project layout

```
nix_utils/
  spin.toml          Project settings
  nix_utils/
    nix_helpers.rb   Shared helper functions used by many tools
    file_ext.rb      Bindings to native C file operations
    sp_file_ext.c    Native C code for file operations not in Spinel yet
    proc_ext.rb      Bindings to native C process operations
    sp_proc_ext.c    Native C code for process operations not in Spinel yet
    checksum_tool.rb Shared code for all the checksum tools (md5sum, sha*sum)
  bin/
    cat.rb           Each file here is one tool
    grep.rb
    ls.rb
    ...
  test/
    test_file_ext.rb Tests for the native C file extension
  man/
    cat.1.txt        Plain-text manual page for each tool
    grep.1.txt
    ...
  build/             Compiled binaries go here (do not commit this folder)
```

## Reading the manual pages

Each tool has a plain-text manual page in the `man/` folder written in
simple language. To read one, open it in any text viewer:

```sh
cat man/grep.1.txt
```

Or pipe it through a pager:

```sh
cat man/sort.1.txt | less
```

## Running the tests

```sh
spin test
```

## License

MIT — see [LICENSE](LICENSE).
