//
//  SwiftParser.swift
//  IBAnalyzer
//
//  Created by Arkadiusz Holko on 26-12-16.
//  Copyright © 2016 Arkadiusz Holko. All rights reserved.
//

import Foundation
import SourceKittenFramework

protocol SwiftParserType {
    func mappingForFile(at url: URL, result: inout [String: Class]) throws
    func mappingForContents(_ contents: String, result: inout [String: Class]) throws
}

enum SwiftParserError: Error {
    case incorrectPath(path: String)
}

class SwiftParser: SwiftParserType {
    func mappingForFile(at url: URL, result: inout [String: Class]) throws {
        if let file = File(path: url.path) {
            return try mapping(for: file, result: &result)
        } else {
            throw SwiftParserError.incorrectPath(path: url.path)
        }
    }

    func mappingForContents(_ contents: String, result: inout [String: Class]) throws {
        return try mapping(for: File(contents: contents), result: &result)
    }

    private func mapping(for file: File, result: inout [String: Class]) throws {
        let fileStructure = try Structure(file: file)
        let dictionary = fileStructure.dictionary

        parseSubstructure(dictionary.substructure, result: &result, file: file)
    }

    private func parseSubstructure(_ substructure: [[String: SourceKitRepresentable]],
                                   result: inout [String: Class],
                                   file: File) {

        for structure in substructure {
            var outlets: [Declaration] = []
            var actions: [Declaration] = []
            printLog("structure "+String(describing: structure))

            if let kind = structure["key.kind"] as? String,
                let name = structure["key.name"] as? String,
                kind == "source.lang.swift.decl.class" || kind == "source.lang.swift.decl.extension" {
                printLog("name "+String(describing: name))

                for insideStructure in structure.substructure {
                    if let attributes = insideStructure["key.attributes"] as? [[String: AnyObject]],
                        let propertyName = insideStructure["key.name"] as? String {

                        let isOutlet = attributes.contains { dict -> Bool in
                            return dict.values.contains(where: { $0 as? String == "source.decl.attribute.iboutlet" })
                        }

                        if isOutlet, let nameOffset64 = insideStructure["key.nameoffset"] as? Int64 {
                            printLog("Declaration "+String(describing: propertyName))
                            outlets.append(Declaration(name: propertyName, file: file, offset: nameOffset64, isOptional: insideStructure.isOptional))
                        }

                        let isIBAction = attributes.contains { dict -> Bool in
                            return dict.values.contains(where: { $0 as? String == "source.decl.attribute.ibaction" })
                        }

                        if isIBAction, let selectorName = insideStructure["key.selector_name"] as? String,
                            let nameOffset64 = insideStructure["key.nameoffset"] as? Int64 {
                            printLog("Declaration "+String(describing: selectorName))
                            actions.append(Declaration(name: selectorName, file: file, offset: nameOffset64))
                        }
                    }
                }

                parseSubstructure(structure.substructure, result: &result, file: file)
                let inherited = extractedInheritedTypes(structure: structure)
                let existing = result[name]

                // appending needed because of extensions
                result[name] = Class(outlets: outlets + (existing?.outlets ?? []),
                                              actions: actions + (existing?.actions ?? []),
                                              inherited: inherited + (existing?.inherited ?? []))
            }
        }
    }

    private func extractedInheritedTypes(structure: [String: SourceKitRepresentable]) -> [String] {
        guard let inherited = structure["key.inheritedtypes"] as? [[String: String]] else {
            return []
        }

        let result = inherited.map { $0["key.name"] }.compactMap { $0 }
        return result
    }
}

private extension Dictionary where Key: ExpressibleByStringLiteral {
    var substructure: [[String: SourceKitRepresentable]] {
        let substructure = self["key.substructure"] as? [SourceKitRepresentable] ?? []
        return substructure.compactMap { $0 as? [String: SourceKitRepresentable] }
    }

    var isOptional: Bool {
        if let typename = self["key.typename"] as? String,
            let optionalString = typename.last {
            return optionalString == "?"
        }
        return false
    }
}
