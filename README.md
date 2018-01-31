# OysterKit

OysterKit enables native Swift scanning, lexical analysis, and parsing capabilities as a pure Swift framework. Two additional elements are also provided in this package. The first is a second framework STLR which uses OysterKit to provide a plain text grammar specification language called STLR (Swift Tool for Language Recognition). Finally a command line tool, ````stlr```` can be used to automatically generate Swift source code for OysterKit for STLR grammars, as well as dynamically apply STLR grammars to a number of use-cases. The following documentation is available: 

 - [OysterKit API Documentation](https://rawgit.com/SwiftStudies/OysterKit/master/Documentation/OysterKit/index.html) Full API documentation for the OysterKit framework
 - [STLR API Documentation](https://rawgit.com/SwiftStudies/OysterKit/master/Documentation/STLR/index.html) Full API documentation for the STLR framework
 	- [STLR Language Reference](https://github.com/SwiftStudies/OysterKit/blob/master/Documentation/STLR.md) A guide with examples to using the STLR language to define grammars
 	- [Tutorials](https://github.com/SwiftStudies/OysterKit/tree/master/Documentation/Tutorials) Tutorials for using OysterKit and STLR for defining and exploiting grammars. 
 - [stlrc Command Line Tool reference](https://github.com/SwiftStudies/OysterKit/blob/master/Documentation/stlrc-tool.md) Instructions for using the ````stlrc```` command line tool. Note that some of the tutorials referenced above also provide some concrete usage examples.


## Key Features

  - **OysterKit** Provides support for scanning strings
	  - Fully supports direct and indirect left hand recursion in rules
	  - Provides support for parsing strings using defined rules as streams of tokens or constructing Abstract Syntax Trees (ASTs)
	  - All of the above provided as implementations of protocols allowing the replacement of any by your own components if you wish
	  - Create your own file decoders (using Swift 4's Encoding/Decoding framework `Encodable` and `Decodable`) 
  - **STLR** Provides support for defining scanning (terminal) and parsing rules
  	- A lexical analysis and parser definition language, STLR, which can be compiled at run-time in memory, or from stored files
  	- Complied STLR can be used immediately at run time, or through the generation of a Swift source file

## Status

  - All tests are passing

For those that used v1.0 there are significant performance and capability benefits of moving to v2. I have not yet built an OKScript translator, but that could quite easily be done if there is demand. 

