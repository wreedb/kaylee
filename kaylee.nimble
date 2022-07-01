# Package
version       = "0.0.1"
author        = "wvanisb"
description   = "AUR helper written in Nim!"
license       = "BSD 2-Clause"
srcDir        = "."
installExt    = @["nim"]
bin           = @["kaylee"]

# Deps
requires "nim"
requires "zippy"
requires "yaml@#heads"
requires "https://github.com/skellock/crappycli.git"
