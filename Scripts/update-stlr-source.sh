echo -e "public let STLRSource = \"\"\"\n" > Sources/TestingSupport/STLRSource.swift
cat Resources/STLR.stlr >> Sources/TestingSupport/STLRSource.swift
echo -e "\n\"\"\"" >> Sources/TestingSupport/STLRSource.swift
sed 's/\\/\\\\/g' < Sources/TestingSupport/STLRSource.swift > Sources/TestingSupport/STLRSource.swift2
mv Sources/TestingSupport/STLRSource.swift2 Sources/TestingSupport/STLRSource.swift
