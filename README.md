# OysterKit

OysterKit is a framework that provides a native Swift scanning, lexical analysis, and parsing capabilities. In addition it provides a language that can be used to rapidly define the rules used by OysterKit called STLR (see STLR.md). 

For those that used v1.0 there are significant performance and capability benefits of moving to v2. I have not yet built an OKScript translator, but that could quite easily be done if there is demand. 

## Key Features

  - Provides support for scanning strings
  - Provides support for defining scanning (terminal) and parsing rules
  - Fully supports direct and indirect left hand recursion in rules
  - Provides support for parsing strings using defined rules as streams of tokens or constructing Abstract Syntax Trees (ASTs)
  - All of the above provided as implementations of protocols allowing the replacement of any by your own components if you wish
  - Create your own file decoders (using Swift 4's Encoding/Decoding framework `Encodable` and `Decodable`) 
  - A lexical analysis and parser definition language, STLR, which can be compiled at run-time in memory, or from stored files
  - Complied STLR can be used immediately at run time, or through the generation of a Swift source file

## Status

  - All tests are passing
  - Some example products will be added shortly to provide some concrete usage examples
