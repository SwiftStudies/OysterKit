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

#### Command Specific Options

 * ````--grammar, -g````: Takes a single parameter which identifies the .stlr Grammar to use for parsing
 * ````--optimize, -o````: Applies optimizations to the parsed Grammar before profiling

### profile

Profiling enables signpost generation during parsing of the supplied grammar. Use instruments to review the performance of your grammar

#### Command Specific Options

* ````--grammar, -g````: Takes a single parameter which identifies the .stlr Grammar to use for parsing
* ````--optimize, -o````: Applies optimizations to the parsed Grammar before profiling

### generate

Supports the creation of 

#### Command Specific Options

 * ````--grammar, -g````: Takes a single parameter which identifies the .stlr Grammar to use for parsing
 * ````--optimize, -o````: Applies optimizations to the parsed Grammar before profiling
 * ````--language, -l````: The output language to generate. Supported values are  ````Swift```` (generates Swift implementation of the tokens and rules, building into a Homogenous tree) and ```SwiftIR``` which generates not only the tokens and rules but a data structure (IR) that can subsequently be constructed using a ```String```. See below for some guidance on structuring your grammar to support automatic Intermediate Representation generation.  
 * ````--output-to, -ot````: Takes a single parameter which identifies the file or folder where the generated file should be stored. If the parameter ends with a / the name of the input grammar will be used to determine the name of the expected output grammar. For example ````stlrc generate -g MyLang.stlr -ot /Sources/```` would create a Swift source ````/Sources/MyLang.swift```` 

#### Automatic Generation of Intermediate Representations
Whilst ```stlrc``` can automatically generate a valid Swift representation of the data-structures described by your grammar, in order to fully automate parsing into that intermediate representation some consideration must be given to the implied
structure your grammar describes. In general, making sure the fully automated flow is available to you is not difficult, and the benefits of having a full parsing code path into a Swift data structure far outweigh the small amount of work required to achieve this. However, if you do not want to do this work you can instead implement your own custom ```init(from decoder:Decoder)``` functions on top of the generated code instead. This is typically much more work. 

##### Don't Mix array types in a single node

Consider the following grammar

    name = .letters+ -.whitespace
    age  = .decimalDigit+ -.whitespace
    
    list = name+ age+ -.whitespace*
    
This can be easily parsed into a dictionary. However when we look at the generated we can see the root of the problem

    /// List
    struct List : Decodable {
        let age : [Swift.String]
        let name : [Swift.String]
    }

The structure that comes from parsing will be 

    list
        name - Tom
        name - Dick
        name - Harry
        age - 42
        age - 67
        age - 15
        
And the decoding parser will not be able to find an actual array of Strings. To overcome this we simply need to group all names into their own node, and the same for ages, enabling the IR generator to represent that structure in a way that can be easily parsed

    /// Names
    typealias Names = [Swift.String]
    /// Ages
    typealias Ages = [Swift.String]
    /// List
    struct List : Decodable {
        let names : Names
        let ages : Ages
    }

Which will be built from the parsed data

    list
        names
            name - Tom
            name - Dick
            name - Harry
        ages
            age - 42
            age - 67
            age - 15

## Installation

Type the following commands to build and install ````stlrc````. 

	swift run -c release stlrc install
	
This will install the ```stlrc``` command in ```/usr/local/bin``` if you would like to specify an alternative location then this can be done with the ````--location```` option. For example, to install into ````/usr/bin```` you would type

	swift run -c release stlrc install --location /usr/bin/


