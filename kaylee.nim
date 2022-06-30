import lib/libkaylee, lib/textfmt;
import crappycli;
import std/strutils, strformat;
import os 

if not existsOrCreateDir(&"{homeDir}/.cache"):
  quit(1)
if not existsOrCreateDir(&"{homeDir}/.cache/kaylee"):
  quit(1)
let originalDir = getCurrentDir();
setCurrentDir(&"{homeDir}/.cache/kaylee")
discard execShellCmd(&"rm -Rf -- */ && rm -Rf -- *.tar.gz");
setCurrentDir(originalDir)

if not fileExists(fileloc):
  discard execShellCmd(&"touch {fileloc}")

# new crappy cli!
let cli = newCrappyCli()

if cli.empty: 
  echo "no argument given\n use --help for more information"
  quit(1)

var firstarg = toLowerAscii(cli.first);
let secondarg = toLowerAscii(cli.second);


const opts = ["s", "u", "i", "q", "r"]

if not opts.contains(firstarg):
  echo &"kaylee doesn't know the command {firstarg}\n use --help to see available commands"


proc emptyargs(secondarg: string): string =
  if secondarg.isEmptyOrWhitespace():
    echo "no package name given"
    quit(1)
  else:
    result = secondarg;

case firstarg:
  of "u":
    createMyYaml();
    perlfixyaml(fileloc);
    update(); #?
    discard updatepkglist();
  of "s":
    search(emptyargs(secondarg));
  of "i":
    install(emptyargs(secondarg));
    discard updatepkglist();
  of "q":
    showInstalled();
  of "r":
    if secondarg.isEmptyOrWhitespace():
      echo "no package name given"
      quit(1)
    else:
      createMyYaml();
      perlfixyaml(fileloc);
      removePackage(emptyargs(secondarg));
      discard updatepkglist();
