# This is just an example to get you started. A typical binary package
# uses this file as the main entry point of the application.
import dotenv
from std/os import getEnv, fileExists, existsEnv
import std/[terminal, sequtils]
import csvtable, strutils
import tables
import tinyre
import encodings

proc readFile*(filePath:string,
               sourceEncoding:string,
               destEncoding:string = "UTF8"): string =
  var file:File
  if not open(file, filePath):
    raise newException(IOError,"Could not open file:" & filePath)
  defer:file.close()
  let text = file.readAll()
  if cmpIgnoreCase(destEncoding,sourceEncoding) != 0 :
    result = text.convert(destEncoding, sourceEncoding)
  else:
    result = text

when isMainModule:
  overload()

  stdout.styledWriteLine {styleBright, styleBlink, styleUnderscore}, "Copyright (C) Hamzah Al-washali 2023."
  stdout.styledWriteLine fgGreen, "\nPrint POS entries from two inputs, database and items."
  stdout.styledWriteLine fgBlue, "In case you want to edit any of the inputs or output file names, you can change them from .env file."

  var isError = false
  if not existsEnv("DATABASE_INPUT_FILE"):
    stdout.styledWriteLine fgRed, "DATABASE_INPUT_FILE Variable does not exist in .env file, check and run again."
    isError = true
  if not existsEnv("POS_INPUT_FILE"):
    stdout.styledWriteLine fgRed, "POS_INPUT_FILE Variable does not exist in .env file, check and run again."
    isError = true
  if not existsEnv("OUTPUT_FILE"):
    stdout.styledWriteLine fgRed, "OUTPUT_FILE Variable does not exist in .env file, check and run again."
    isError = true

  if isError:
    system.quit 1

  let database_f = getEnv("DATABASE_INPUT_FILE")
  let pos_f = getEnv("POS_INPUT_FILE")
  let output_f = getEnv("OUTPUT_FILE")

  if not fileExists(database_f):
    stdout.styledWriteLine fgRed, "DATABASE_INPUT_FILE's File Does Not Exist, check and run again."
    isError = true
  if not fileExists(pos_f):
    stdout.styledWriteLine fgRed, "POS_INPUT_FILE's File Does Not Exist, check and run again."
    isError = true

  if isError:
    system.quit 1

  var items = newTable[string, int]()
  let f_pos = readFile(pos_f, "UTF16")
  let posContent = f_pos.replace(reG("  +"), "\n").replace(reG("\r"), "")

  for line in posContent.split('\n'):
    if line.isEmptyOrWhitespace or not isDigit(line[0]):
      continue
    let lineWithLeadingZeros = intToStr(parseInt(line), 13)
    if items.hasKey lineWithLeadingZeros:
      items[lineWithLeadingZeros] += 1
    else:
      items[lineWithLeadingZeros] = 1

  var csvIn = newCSVTblReader(database_f, '\t')
  var csvOutput = newCSVTblWriter(output_f, csvIn.headers, '\t')
  for row in csvIn:
    for key in items.keys:
      if row[csvIn.headers[0]] == key:
        for oitem in repeat(row, items[key]):
          csvOutput.writeRow(oitem)
        break

  csvIn.close
  csvOutput.close

  stdout.styledWriteLine fgGreen, "\n\nDONE."
