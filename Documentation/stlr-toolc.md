# Index

 - [Usage](usage)
 - [Installation](installation)
 - Tutorials
 	- [Bork - A command line text adventure using OysterKit and STLR](https://github.com/SwiftStudies/OysterKit/Documentation/Tutorials/Bork) 


# Usage

The basic usage pattern for ````stlrc```` is as follows

	stlrc [command] [[option] parameter], [[option] parameter]

## Commands

The following options apply to all commands

 * ````--help, -h````: Display usage information for the chosen command
 * ````--version, -V````: Provide version information for the current command

If no command is specified, the default will be used

### parse (Default)

Parses a set of input files according using the supplied grammar

### Command Specific Options

 * ````--grammar, -g````: Takes a single parameter which identifies the .stlr Grammar to use for parsing

### Generate



### Command Specific Options

 * ````--grammar, -g````: Takes a single parameter which identifies the .stlr Grammar to use for parsing
 * ````--language, -l````: The output language to generate. Currently the only supported value is ````Swift```` 
 * ````--output-to, -ot````: Takes a single parameter which identifies the file or folder where the generated file should be stored. If the parameter ends with a / the name of the input grammar will be used to determine the name of the expected output grammar. For example ````stlrc generate -g MyLang.stlr -ot /Sources/```` would create a Swift source ````/Sources/MyLang.swift```` 


## Installation

Type the following commands to build and install ````stlrc````. 

	swift run -c release stlrc install
	
This will install the ```stlrc``` command in ```/usr/local/bin``` if you would like to specify an alternative location then this can be done with the ````--location```` option. For example, to install into ````/usr/bin```` you would type

	swift run -c release stlrc install --location /usr/bin/


