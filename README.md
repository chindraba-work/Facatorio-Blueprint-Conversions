# Factorio Blueprint Conversions

## Contents

-  [Description](#description)
-  [Requirements](#requirements)
-  [Installation](#installation)
-  [Usage](#usage)
  -  [Commands](#commands)
  -  [Options](#options)
  -  [File Names](#file-names)
    -  [Input File](#input-file)
    -  [Output File](#output-file)
-  [Limitations](#limitations)
-  [Versioning](#versioning)
-  [Copyright and License](#copyright-and-license)
  -  [The MIT License](#the-mit-license)


---
## Description

Perl program to read and write Factorio blueprint export strings. Blueprint export strings allow players of [Factorio](https://www.factorio.com/), an excellent game from Wube Software Ltd, to save and share blueprints and blueprint collections with other players. Wube defines the blueprint string as:

> A blueprint string is a JSON representation of the blueprint, compressed with zlib deflate using compression level 9 and then encoded using base64 with a version byte in front of the encoded string. The version byte is currently 0 (for all Factorio versions through 1.0). So to get the JSON representation of a blueprint from a blueprint string, skip the first byte, base64 decode the string, and finally decompress using zlib inflate. [Source](https://wiki.factorio.com/Blueprint_string_format)

[TOP](#contents)

---
## Requirements

The requirements for this program is a working Perl installation with the following packages available:
-  Compress::Zlib
-  MIME::Base64
-  JSON::PP (core)

Of the three, Compress::Zlib is the most likely to not already be installed on a system which has been use for a while. It is also the hardest one to find useful commmand line tools for, which prompted the creation of this project.


[TOP](#contents)

---
## Installation

Copy the Perl file to any place in your execution search path. Use `echo $PATH` on Linux and `echo %PATH%` on Windows to see what that is. For Linux, verify that the execute privilege is set. It should be, but check.

[TOP](#contents)

---
## Usage

Copy the export string for a blueprint, or blueprint book, from the dialog box Factorio shows it in. Save  that to a file on you system. While in the same directory as the new file, calling it `my-print.txt` for now, execute the command `fact-bp.pl read my-print.txt`. A new file `my-print.json` will be created with the minified JSON from the blueprint. Edit as needed and resave it. Use the command `fact-bp.pl write my-print.json my-new-print.txt` which makes the named file. Copy the contents of that and import the blueprint in Factorio.

[TOP](#contents)

### Commands

There are really only 4 commands in the program: `decode`, `encode`, `version`, and `help`.

`decode` has aliases `read` and `open`
`encode` has aliases `make`, `write` and `save`
`version` has the alias `ver`
`help` has the alias `?`

In addition, the commands, and there aliases, except for `?`, can be preceded by double-dash, abbreviated to a single letter, or a single letter preceded by a single dash. Thus for the `decode` command you can use `decode`,`--decode`,`-d`, and `d` as well as the same variations for `read`, `open`, and `version`. `help` can be treated thusly as well, while `?` is unprefixed and obviously has no abbreviation possible. In all cases, upper and lower case letters are treated the same.

`decode` is the process of converting the blueprint export string to a JSON string.
`encode` is the process of converting a JSON string to a blueprint export string (for importing).

[TOP](#contents)

### Options

There is only one option available `-p`, or `-P`. During the `decode` opperation the JSON string is created from the uncompressed data. This is stored by Factorio as a single, often very long, line of text.
Humans do better with some structure, and the `-p` option provides that with "Pretty Printing." If you're going to be editing the JSON by hand, the `-p` option is you friend. If you're going to use some kind of text processing tool (`sed`, `awk`, or some RegEx commands) then the single line version can be slightly faster to process. Not always, of course.
The `encode` operation will always convert to a single string first, then do the processing. First, that's the way Wube does it, so it's best to follow their process on their data. Second, it makes for a smaller export string, which for some blueprint books can be significant.

[TOP](#contents)

### File Names

At least one filename must be given, the source file, for either operation. There is no default name. There is default extensions, thought. The handling, and creation of, extensions follows what I think is a reasonable chain. In the case of the source file, and if given the output file, the use of a trailing period without an extension will override any extension creation the program might make. Overriding the extension mechanism for the source file will not automatically override it for the output file. The descriptions below deal with reading Wube data writing JSON data. Exchange the `.txt` and `.json` in them for filenames going from JSON data to Wube data.

#### Input File

The input file will be checked by the exact name given first. If it exists, that file is used.
If not found, the program will try adding `.txt` to the end of the file and search again.
If that fails, the program will fail.
Even though it's a waste of time on Windows, both `.txt` and `.TXT` will be attempted.
The `.txt` extension was chosen because many programs which handle text files will add that by default, and the export string copied from Factorio has to be saved somehow. In addition, if the blueprint is downloaded from somewhere, the [Factorio Prints](https://factorioprints.com/) page perhaps, the browser will probably add the `.txt` to the file as well. Lastly, as a final "authority" on the subject, tbe blueprint bot on the Factorio Discord server expects prints to have a `.txt` extension.

So, if you use the filename `my-print.dat` and it exists, it will be loaded. If not, and `my-print.dat.txt` exists, it will be loaded. Otherwise, nothing happens. If you use `my-print.` (notice the final period), and `my-print.` exist, it will be loaded and if `my-print` (no dot and no extension) exists, it will be loaded. If neither exists, the program will _not_ look for `my-print.txt`, it will just quit.

#### Output File

An extra rule here: the output file **must not** exist, at all, period. Full stop. End of sentence.
There are, and will not be, provisions for the user to be prompted to override an existing file. The program is intended to be used as part of a script and interruptions to prompt the user don't do well for automated processing.

The name of the output file does not need to be given. The program will try to make a new file out of the input filename by changing `.txt` to `.json`, if it has `.txt`, or just adding `.json` to whatever there is. `my-print.txt` will become `my-print.json` and `my-print.z` will become `my-print.z.json`. If you cancelled extension searching on the input, `my-print.`, then `my-print` will still become `my-print.json` anyway. Otherwise it would be overwriting the input file, a bad choice in almost any situation.

The output filename _can_ be given, however. If a name is given the program goes through a set of conditions to see what the name should be, first one through the gate is the winner.

-  If the name has no period anywhere, add `.json`
-  If the name ends with a period, strip that period and use the rest, _as-is_
-  If the name ends with `.json` keep it as is
-  Add `.json` to whatever was typed

Making `.json` as the semi-default helps keep things organized. It helps the editor, if you use it, know what to do with the file. (Color coding is really nice when trying to read JSON data.) It also, without an escape, leaves the user out of control of the final name. That escape is the final period override. Using the final period tells the program to accept the rest of the name (without that period) as the name to use. If, by some stroke of fate, you really do want the new filename to end with a period, use two. `my-print..` will become `my-print.`

Unlike the selection for the input name, the output name selection process _does not_ test for an existing file until the final name choice is worked out. With the input name I can try guessing what the name should be. If I find a file, I'm probably correct. With the output name I can guess, and if I'm wrong you may never know what name to look for when you want to use the file. If the chosen filename exists, the program just quits (after telling you the name it tried to create) so the user can pick a new name themself.

[TOP](#contents)

---
## Limitations

Other than the limits above in filename use the only real limitations of the program are that it is not set to handle IO using pipes, only files, and that it's requirements for JSON are strict.

I don't see adding STDIN/STDOUT to the program. The purpose is for making the blueprint strings something the user can manipulate. There are a few cases, mass renaming for example, where it's possible the the entire process from download through processing and back to upload could be made user-less, but I see them as the exception rather than the rule. The uses wouldn't justify the work.

The restriction placed on JSON data are intentional in the module that handles it, and deliberate on my part for not setting flags to allow exceptions. Wube seems to have done an excellent job in keeping their handling of the data clean, and keeping to the rules of JSON, RFC4672. They also seem to have done well with UTF-8, which JSON is supposed to be in. I've had very few (less than a handfull I think) codepoints which didn't display in the game. I don't expect that Wube created JSON will become invalid, so keeping it strict serves to act as a safety check on edits, manual or automatic, made to the JSON before encoding it again. If an invalid JSON comes from the BP export display in the game, I expect it will be from one of the many mods that exists rather than from Wube, though I expect they've even got filters to trap that. 


[TOP](#contents)

---
## Versioning

The **Factorio Blueprint Conversions** project uses Semantic Versioning v2.0.0.

[Semantic Versioning](https://semver.org/spec/v2.0.0.html) was created by [Tom Preston-Werner](http://tom.preston-werner.com/), inventor of Gravatars and cofounder of GitHub.

Version numbers take the form X.Y.Z where X is the major version, Y is the minor version and Z is the patch version. The meaning of the different levels are:

* Major version increases indicates that there is some kind of change in the API (how this program works as seen by the user) or the program features which is incompatible with previous version

* Minor version increases indicates that there is some kind of change in the API (how this program works as seen by the user) or the program features which might be new, while still being compatible with all other versions of the same major version

* Patch version increases indicate that there is some internal change, bug fixes, changes in logic, or other internal changes which do not create any incompatible changes within the same major version, and which do not add any features to the program operations or functionality

[TOP](#contents)

---
## Copyright and License

The MIT license applies to all the code within this repository.

Copyright © 2022  Chindraba (Ronald Lamoreaux)

   <[projects@chindraba.work](mailto:projects@chindraba.work?subject=Factorio_Blueprint_Conversions)>

- All Rights Reserved

### The MIT License

    Permission is hereby granted, free of charge, to any person
    obtaining a copy of this software and associated documentation
    files (the "Software"), to deal in the Software without restriction,
    including without limitation the rights to use, copy, modify, merge,
    publish, distribute, sublicense, and/or sell copies of the Software,
    and to permit persons to whom the Software is furnished to do so,
    subject to the following conditions:

    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGE-
    MENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
    FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
    CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[TOP](#contents)
