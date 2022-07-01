import std/httpclient, uri, strformat, strutils, json, parseutils;
import os, osproc, ./textfmt, ./objects;
import yaml/serialization, streams;
import zippy/tarballs;


const homeDir*: string = getEnv("HOME")
let fileloc*: string = &"{homeDir}/.cache/kaylee/packages.yaml"


iterator countTo*(n: int): int =
  var i = 0
  while i < n:
    yield i
    inc i


proc confirmInstall*(name: string): bool = #? installation confirmation
  stdout.write(&" {fm(6)}::{fm(9)} Confirm installation [{fm(8)}y{fm(9)}/{fm(5)}N{fm(9)}] ");
  var choice: string = stdin.readLine();
  if toLower(choice).contains("y") or toLower(choice).contains("yes"):
    result = true;
  else:
    result = false;


proc createMyYaml*() = #? update/create the yaml file
  #? creates the query string for the packages
  #var client = newHttpClient();
  var appndstr = "https://aur.archlinux.org/rpc?v=5&type=info"
  let pacQ = execCmdEx("pacman -Qqem | perl -pe 's/^/\\${/g' | perl -pe 's/\n$/}/g'")
  var outp: seq[tuple[kind: InterpolatedKind, value: string]] = @[]
  for k, v in interpolatedFragments(pacQ[0]):
    outp.add (k, v)
  if outp.len == 0:
    echo "you have no AUR packages installed."; quit(0); #! quit the program if they have no packages.
  discard outp.pop()

  for i in countTo(outp.len):
    var thispkg = outp[i].value
    let ap = &"&arg[]={thispkg}"
    appndstr.add(ap)

  var client = newHttpClient();
  let response = client.getContent(appndstr);
  let parsed = parseJson(response);
  let packagelist = parsed{"results"};
  var pkglist = newSeq[Package]()

  for i in countTo(packagelist.len):
    var package = to(packagelist[i], Package);
    let
      pkgname: string = chkMtStr(package.Name, "name")
      pkgdesc: string = chkMtStr(package.Description, "description")
      pkgvers: string = chkMtStr(package.Version, "version")
      pkgurl:  string = chkMtStr(package.URLPath, "URL")
      pkglmod: int    = package.LastModified
      pkgvote: int    = package.NumVotes
      pkgid:   int    = package.ID
    let newPkg: Package = Package(
      Name: pkgname,
      Description: pkgdesc,
      Version: pkgvers,
      ID: pkgid,
      LastModified: pkglmod,
      URLPath: pkgurl,
      NumVotes: pkgvote);
    pkglist.add(newPkg)
  
  var s = newFileStream(fileloc, fmWrite)
  dump(pkglist, s)
  s.close();


proc updatepkglist*(): string = #? update local yaml
  #? loads installed packages from local file
  var ss = newFileStream(fileloc, fmRead)
  var pkgs: seq[Package] = @[]
  load(ss, pkgs)
  ss.close()

  #? creates the query string for the packages
  var appndstr = "https://aur.archlinux.org/rpc?v=5&type=info"
  let pacQ = execCmdEx("pacman -Qqem | perl -pe 's/^/\\${/g' | perl -pe 's/\n$/}/g'")
  var outp: seq[tuple[kind: InterpolatedKind, value: string]] = @[]
  for k, v in interpolatedFragments(pacQ[0]):
    outp.add (k, v)
  if outp.len == 0:
    echo "you have no AUR packages installed."; quit(0); #! quit the program if they have no packages.
  discard outp.pop()

  for i in countTo(outp.len):
    var thispkg = outp[i].value
    let ap = &"&arg[]={thispkg}"
    appndstr.add(ap);

  var client = newHttpClient();
  let response = client.getContent(appndstr);
  let parsed = parseJson(response);
  let packagelist = parsed{"results"};
  var pkglist = newSeq[Package]()

  for i in countTo(packagelist.len):
    var package = to(packagelist[i], Package);
    let
      pkgname: string = chkMtStr(package.Name, "name")
      pkgdesc: string = chkMtStr(package.Description, "description")
      pkgvers: string = chkMtStr(package.Version, "version")
      pkgurl:  string = chkMtStr(package.URLPath, "URL")
      pkglmod: int    = package.LastModified
      pkgvote: int    = package.NumVotes
      pkgid:   int    = package.ID
    let newPkg: Package = Package(
      Name: pkgname,
      Description: pkgdesc,
      Version: pkgvers,
      ID: pkgid,
      LastModified: pkglmod,
      URLPath: pkgurl,
      NumVotes: pkgvote);
    pkglist.add(newPkg)
  
  var s = newFileStream(fileloc, fmWrite)
  dump(pkglist, s)
  s.close();
  result = fileloc;


proc showInstalled*() = #? pacman -Q
  discard execShellCmd("pacman -Qqme");
  quit(0);


proc removePackage*(name: string) = #? pacman -Rns
  discard execShellCmd(&"sudo pacman -Rns {name}");
  discard updatepkglist();
  quit(0);


proc search*(searchTerm: string) = #? pacman -Ss
  var s = newFileStream(fileloc, fmRead)
  var ipkgs: seq[Package] = @[]
  load(s, ipkgs)
  s.close()
  var installedpkgs: seq[string] = @[]
  for i in countTo(ipkgs.len):
    installedpkgs.add(ipkgs[i].Name)
  var client = newHttpClient();
  let response = client.getContent(&"https://aur.archlinux.org/rpc?v=5&type=search&by=name-desc&arg={searchTerm}");
  let parsed = parseJson(response);
  let packagelist = parsed{"results"};
  for i in countTo(packagelist.len):
    let package = to(packagelist[i], Package);
    let 
      pkgname: string = chkMtStr(package.Name, "name")
      pkgdesc: string = chkMtStr(package.Description, "description")
      pkgvers: string = chkMtStr(package.Version, "version")
    var outputstr: string = "";
    if installedpkgs.contains(pkgname):
      outputstr = &"{fm(6)}{fm(0)}aur{fm(9)}/{fm(0)}{pkgname}{fm(9)} [{fm(8)}{pkgvers}{fm(9)}] * {fm(7)}Installed{fm(9)}\n    {pkgdesc}";
    else:
      outputstr = &"{fm(6)}{fm(0)}aur{fm(9)}/{fm(0)}{pkgname}{fm(9)} [{fm(8)}{pkgvers}{fm(9)}]\n    {pkgdesc}";
    echo outputstr;

  echo &"\n {fm(6)}::{fm(9)} {fm(7)}{fm(0)}kaylee{fm(9)} says '{packagelist.len} packages found'\n";
  quit(0);


proc makePkg*(newpath: string) = #? makepkg -si
  let cwd: string = getCurrentDir();
  setCurrentDir(newpath);
  discard execShellCmd("makepkg -si");
  setCurrentDir(cwd);
  #? update the pkg list
  discard updatepkglist();
  echo "finished install package.\n";
  quit(0);


proc dlTar*(name: string): string = #? tar downloading function
  var
    cachePath: string = &"{homeDir}/.cache/kaylee"
    tarPath: string = &"{cachePath}/{name}.tar.gz"
  # make sure the cache exists
  if not dirExists(cachePath):
    createDir(cachePath);
  # clear out existing name-matched directory
  if dirExists(&"{cachePath}/{name}"):
    removeDir(&"{cachePath}/{name}");
  # clear out exitsing tarfile
  if fileExists(&"{tarPath}"):
    removeFile(&"{tarPath}");
  # download the tarball
  let link = uri.parseUri(&"https://aur.archlinux.org/cgit/aur.git/snapshot/{name}.tar.gz"); 
  let http = newHttpClient();
  downloadFile(http, link, &"{tarPath}");
  extractAll(&"{tarPath}", &"{cachePath}/{name}"); # unzip it
  if confirmInstall(name) == true:
    result = &"{cachePath}/{name}/{name}";
  else:
    echo "exiting..."
    quit(1);


proc install*(searchTerm: string) = #? simple install function
  var client = newHttpClient();
  let response = client.getContent(&"https://aur.archlinux.org/rpc?v=5&type=search&by=name&arg={searchTerm}")
  let
    parsed = parseJson(response)
    packagelist = parsed{"results"}
  var found: string
  for i in countTo(packagelist.len):
    let package = to(packagelist[i], Package);
    let pkgname: string = chkMtStr(package.Name, "name");
    if pkgname == searchTerm:
      found = pkgname;
  if found.isEmptyOrWhitespace():
    echo "no match found"
    quit(1);
  else:
    echo &"{fm(0)}--- --- --- --- --- --- --- --- ---{fm(9)}"
    echo &" {fm(6)}::{fm(9)} {fm(7)}{fm(0)}kaylee{fm(9)} says"
    echo &" {fm(6)}::{fm(9)} package {fm(8)}{searchTerm}{fm(9)} found"
    echo &"{fm(0)}--- --- --- --- --- --- --- --- ---{fm(9)}"
    makePkg(dlTar(found))


proc update*() = # TODO long convoluted update function

  #? loads installed packages from local file
  let fileloc: string = &"{homeDir}/.cache/kaylee/packages.yaml"
  var s = newFileStream(fileloc, fmRead)
  var pkgs: seq[Package] = @[]
  load(s, pkgs)
  s.close()

  #? creates the query string for the packages
  var client = newHttpClient();
  var appndstr = "https://aur.archlinux.org/rpc?v=5&type=info"
  let pacQ = execCmdEx("pacman -Qqem | perl -pe 's/^/\\${/g' | perl -pe 's/\n$/}/g'")
  var outp: seq[tuple[kind: InterpolatedKind, value: string]] = @[]
  for k, v in interpolatedFragments(pacQ[0]):
    outp.add (k, v)
  if outp.len == 0:
    echo "you have no AUR packages installed."; quit(0); #! quit the program if they have no packages.
  discard outp.pop()
  for i in countTo(outp.len):
    var thispkg = outp[i].value
    let ap = &"&arg[]={thispkg}"
    appndstr.add(ap)

  #? uses to qry string to make an array with name and last modified
  var res = client.getContent(appndstr);
  let parsed = parseJson(res);
  let packagelist = parsed{"results"};
  var pkglist = newSeq[UpdatingPackage]()

  for i in countTo(packagelist.len):
    var package = to(packagelist[i], UpdatingPackage);
    let pkgname: string = chkMtStr(package.Name, "name")
    let pkglmod: int = package.LastModified
    let newPkg: UpdatingPackage = UpdatingPackage(Name: pkgname, LastModified: pkglmod)
    pkglist.add(newPkg);

  #? section for finding packages that need update
  var pkgsCanUpdate: seq[string] = @[];

  for i in countTo(pkglist.len):
    var installedpkg = pkgs[i]
    var checkedpkg = pkglist[i]
    var installedlmod = installedpkg.LastModified
    var checkedlmod = checkedpkg.LastModified

    if installedlmod != checkedlmod:
      pkgsCanUpdate.add(checkedpkg.Name)

  if pkgsCanUpdate.len == 0:
    echo "no updates needed, exiting..."
    quit(0)

  #? confirm update
  stdout.write(&" {fm(6)}::{fm(9)} Would you like to update packages? [{fm(8)}y{fm(9)}/{fm(5)}N{fm(9)}] ");
  var choice: string = stdin.readLine();
  if toLower(choice).contains("y") or toLower(choice).contains("yes"):
    for i in countTo(pkgsCanUpdate.len):
      echo &"updating {pkgsCanUpdate[i]}"
      var
        currentpkg = pkgsCanUpdate[i] 
        cachePath: string = &"{homeDir}/.cache/kaylee"
        tarPath: string = &"{cachePath}/{currentpkg}.tar.gz"
      # make sure the cache exists
      if not dirExists(cachePath):
        createDir(cachePath);
      # clear out existing name-matched directory
      if dirExists(&"{cachePath}/{currentpkg}"):
        removeDir(&"{cachePath}/{currentpkg}");
      # clear out exitsing tarfile
      if fileExists(&"{tarPath}"):
        removeFile(&"{tarPath}");
      # download the tarball
      let link = uri.parseUri(&"https://aur.archlinux.org/cgit/aur.git/snapshot/{currentpkg}.tar.gz"); 
      let http = newHttpClient();
      downloadFile(http, link, &"{tarPath}");
      extractAll(&"{tarPath}", &"{cachePath}/{currentpkg}"); # unzip it
      var newpath = &"{cachePath}/{currentpkg}/{currentpkg}";
      let cwd: string = getCurrentDir();
      setCurrentDir(newpath);
      discard execShellCmd("makepkg -si");
      setCurrentDir(cwd);
      echo &"finished installing {pkgsCanUpdate[i]}\n";
      discard updatepkglist();
  else:
    echo &"\n {fm(6)}::{fm(9)} {fm(7)}{fm(0)}kaylee:{fm(9)} exiting...'\n";
    quit(0);

