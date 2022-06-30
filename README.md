# Kaylee - AUR helper written in Nim

## Another AUR helper?
> This is a personal project that I have started as a way to blossom as a developer. I wanted to replace one of my programs with one that I wrote myself, and as of now, I am using Kaylee for managing AUR packages. I have pulled a lot of inspiration from [Paru](https://github.com/morganamilo/paru), [Aura](https://github.com/fosskers/aura) as well as [Yay](https://github.com/Jguer/yay)  
### What's the name all about?
> This project is named after and dedicated to my amazing, supportive and lovely fiance, Kaylee.
### Building Kaylee from source
> **Dependencies:**
* nim
* perl

```
sudo pacman -S nim perl
```
> **Building**
```
git clone https://github.com/wvanisb/kaylee  ## or ##  gh repo clone wvanisb/kaylee
cd kaylee
nimble install yaml
mv lib/presenter.nim ~/.nimble/pkgs/yaml-your-version-here/yaml/presenter.nim
nimble install
```
> Run the Nim compiler
```
nim compileToC -d:ssl -d:release --threads:on --app:console --opt:speed -o:kaylee kaylee.nim
./kaylee u
```
> You can run Kaylee by using either:
```
./kaylee [option] (argument)
```
> or
```
sudo cp kaylee /usr/local/bin
kaylee [option] (argument)
```
<br>

## Options and arguments
> Kaylee currently only supports using **one** argument for options, and the options are _not_ case sensitive
* option **s** will search for the following argument in the AUR  
* option **i** to install a package  
* option **r** will remove a  
* option **q** will query your locally installed AUR packages
* option **u** will update any your outdated AUR packages

## Feedback  
> There will be bugs! I am seeking feedback on the project and I am not opposed to letting others contribute if I think the contributions are good for Kaylee. To give feedback, you can [email me here](mailto:wreedb@yandex.com).
