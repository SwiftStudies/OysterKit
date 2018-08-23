#First generates and puts in Example languages for testing
swift run stlrc generate -g Resources/STLR.stlr -l swift -o -ot Sources/ExampleLanguages/

#If testing is successful copies it into the correct location of GeneratedSources
swift test && cp Sources/ExampleLanguages/STLR.swift Sources/STLR/GeneratedSources/_STLR.swift
