## Description

The unite or unite.vim plug-in can search and display information from
arbitrary sources like files, buffers, recently used files or registers.  You
can run several pre-defined actions on a target displayed in the unite window.

The difference between unite and similar plug-ins like fuzzyfinder,
ctrl-p or ku is, unite provides an integration interface for several
sources and you can create new interface using unite.

## Usage

In case you run unite to display files and buffers as sources to pick
from.

	:Unite file buffer


In case you run unite with an initial filter value (foo) to narrow
down files.

	:Unite -input=foo file


If you start unite it splits the window horizontally and pops up
from the top of Vim by default. 

	:Unite file

The example call above lists all the files in the current directory. You can
choose one of them in the in the unite window by moving the cursor up and down
as usual with j and k. If you type Enter on an active candidate it will open
it in a new buffer. Enter triggers the default action for a candidate which is
"open" for candidates of the kind "file". You can also select an alternative
action for a candidate with <Tab>. See also `unite-action` to read on about
actions.

You can also narrow down the list of candidates by a keyword. If you change
into the insert mode inside of a unite window, the cursor drops you behind the
">" in the second line from above. There you can start typing to filter the
candidates.  You can also use the wild card "*" as an arbitrary character
sequence. For example, 

	*hisa

matches hisa, ujihisa, or ujihisahisa. Furthermore, two consecutive wild cards
match a directory recursively. 

	**/foo

So the example above matches bar/foo or buzz/bar/foo.
Note: The unite action `file_rec` does a recursive file matching by default
without the need to set wildcards.

You can also specify multiple keywords to narrow down the candidates. Multiple
keywords need to be separated either by a space " " or a dash "|". The
examples below match for candidates that meet both conditions "foo" and "bar".

	foo bar
	foo|bar

You can also specify negative conditions with an exclamation mark "!".  This
matches candidates that meet "foo" but do not meet "bar".

	foo !bar

Wild cards are added automatically if you add a "/" in the filter and you have
specified "files" as the buffer name with the option "-buffer-name". That's
handy in case you select files with unite.

	:Unite -buffer-name=files file

See also `unite_default_key_mappings` for other actions.

There is also a screencast available which shows unite in action. Thanks to
ujihisa! http://www.ustream.tv/recorded/11240673

## Install details

Install the distributed files into your Vim script directory which is usually
`~/.vim/`, or `$HOME/vimfiles` on Windows. You should consider to use one of the
famous package managers for Vim like vundle or neobundle to install the
plugin.

After installation you can run unite with the `:Unite` command and append the
sources to the command you wish to select from as parameters. However, it's a
pain in the ass to run the command explicitly every time, so I recommend you
to set a key mapping for the command. See `:h unite`.

## Links

unite plugins(in Japanese): https://github.com/Shougo/unite.vim/wiki/unite-plugins

