## OysterKit

<img style="float: left;" src="Resources/Artwork/Images/OysterKit%20180x180.png">

|       	| Status|
| --------- | :-----|
| Linux/macOS/iOS/tvOS      | [![Build Status](https://travis-ci.org/SwiftStudies/OysterKit.svg?branch=master)](https://travis-ci.org/SwiftStudies/OysterKit)  |
| Test Coverage    | [![codecov](https://codecov.io/gh/SwiftStudies/OysterKit/branch/master/graph/badge.svg)](https://codecov.io/gh/SwiftStudies/OysterKit)    |
| Documentation Coverage      | 97% |  

OysterKit enables native Swift scanning, lexical analysis, and parsing capabilities as a pure Swift framework. Two additional elements are also provided in this package. The first is a second framework STLR which uses OysterKit to provide a plain text grammar specification language called STLR (Swift Tool for Language Recognition). Finally a command line tool, ````stlr```` can be used to automatically generate Swift source code for OysterKit for STLR grammars, as well as dynamically apply STLR grammars to a number of use-cases. The following documentation is available: 

 - [OysterKit API Documentation](https://rawgit.com/SwiftStudies/OysterKit/master/Documentation/OysterKit/index.html) Full API documentation for the OysterKit framework
 - [STLR API Documentation](https://rawgit.com/SwiftStudies/OysterKit/master/Documentation/STLR/index.html) Full API documentation for the STLR framework
 	- [STLR Language Reference](https://github.com/SwiftStudies/OysterKit/blob/master/Documentation/STLR.md) A guide with examples to using the STLR language to define grammars
 	- [Tutorials](https://github.com/SwiftStudies/OysterKit/tree/master/Documentation/Tutorials) Tutorials for using OysterKit and STLR for defining and exploiting grammars. 
 - [stlrc Command Line Tool reference](https://github.com/SwiftStudies/OysterKit/blob/master/Documentation/stlr-toolc.md) Instructions for using the ````stlrc```` command line tool. Note that some of the tutorials referenced above also provide some concrete usage examples.

__Please note__ all development is now for Swift 4.2 and beyond only. If you wish to use the last Swift 4.1 compatible release please use the ```swift/4.2``` branch 

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
 -  You will notice there are a large (>40) number of warnings in this build. You should not be concerned by these as they are largely forward references to further clean up that can be done now that STLR is generating the Swift code for both Rules/Tokens as well as the data-structures for itself. Deprication messages have been added to help you migrate your code to the new API, and this is the last release that will support the old API. 
 - All tests are passing

For those that used v1.0 there are significant performance and capability benefits of moving to v2. I have not yet built an OKScript translator, but that could quite easily be done if there is demand. 

