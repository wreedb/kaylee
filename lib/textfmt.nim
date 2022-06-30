import std/strformat
import os

#[ text-fmt ]#
func fm*(inp: int) : string = #? text formatting function
  const formats: array = [  
      "\X1B[1m",          # 0 bold
      "\X1B[3m",          # 1 italic
      "\X1B[3m\X1B[1m",   # 2 bolditalic
      "\X1B[4m",          # 3 underline
      "\X1B[9m",          # 4 strikethrough
      "\X1B[31m",         # 5 red
      "\X1B[34m",         # 6 blue
      "\X1B[35m",         # 7 pink
      "\X1B[32m",         # 8 green
      "\X1B[0m"     ];    # 9 end format
  result = formats[inp];

proc perlfixyaml*(fname: string) = #? for removing double quotes from yaml
  discard execShellCmd(&"perl -pi -e 's/\"//g' {fname}")

#[ checkEmpty ]#
func chkMtStr*(inp: string, field: string): string = #? check for empty sting & replace
  if inp == "":
    result = &"No {field} provided..."
  else:
    result = inp;
