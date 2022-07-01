import lib/libkaylee;
import crappycli;
import std/strutils, strformat;
import os 

let helpstr: string = &"\nKaylee | AUR helper written in Nim\n  s => search for a package\n  i => install a package\n  u => update packages\n  r => remove a package\n  q => query installed packages";

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
  echo "no argument given\n use 'kaylee help' for more information"
  quit(1)

var firstarg = toLowerAscii(cli.first);
let secondarg = toLowerAscii(cli.second);


const opts = ["s", "u", "i", "q", "r", "h", "help"]

if not opts.contains(firstarg):
  echo &"kaylee doesn't know the command {firstarg}\n use 'kaylee help' to see available commands"


proc emptyargs(secondarg: string): string =
  if secondarg.isEmptyOrWhitespace():
    echo "no package name given"
    quit(1)
  else:
    result = secondarg;

case firstarg:
  of "u":
    createMyYaml();
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
      removePackage(emptyargs(secondarg));
      discard updatepkglist();
  of "help":
    echo helpstr;
  of "h":
    echo helpstr;