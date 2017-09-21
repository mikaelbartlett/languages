//
//  Language.swift
//  languagesPackageDescription
//
//  Created by Mikael Bartlett on 2017-09-21.
//

import Foundation
import CSV

enum OptionType: String {
    case csv = "csv"
    case strings = "strings"
    case help = "h"
    case unknown
    
    init(value: String) {
        switch value {
        case "csv": self = .csv
        case "strings": self = .strings
        case "h": self = .help
        default: self = .unknown
        }
    }
}

class Languages {

    let consoleIO = ConsoleIO()

    func staticMode() {
        var arguments = CommandLine.arguments[1...]
        
        var options: [OptionType: String] = [:]
        
        while let argument = arguments.popFirst() {
            let option = OptionType(value: String(argument[argument.index(argument.startIndex, offsetBy: 2)...]))
            switch option {
            case .csv:
                guard let value = arguments.popFirst() else {
                    consoleIO.printUsage()
                    return                    
                }
                options[.csv] = value
            case .strings:
                guard let value = arguments.popFirst() else {
                    consoleIO.printUsage()
                    return
                }
                options[.strings] = value
            // Future support for multiple outputs (iOS/Android)
            /*case .output:
                var platformTypes: [PlatformType] = []
                while let value = arguments.first, !value.starts(with: "--") {
                    arguments.removeFirst()
                    let platformType = PlatformType(value: value)
                    platformTypes.append(platformType)
                }
                outputs.append(contentsOf: platformTypes)*/
            case .help:
                consoleIO.printUsage()
                return
            case .unknown:
                consoleIO.printUsage()
                return
            }
        }
        if let csvFile = options[.csv], let strings = options[.strings] {
            let hashmap = csvFileToHashmap(file: csvFile)
            hashmapToStrings(from: strings, translations: hashmap)
        }
    }
    
    /**
     Creates an array of hashmaps from file at path.
     
     - Parameters:
         - file: full path to csv file
     
     - Returns: An array of hashmaps. Each array is a translation column from csv
     */
    private func csvFileToHashmap(file: String) -> [[String: String]] {
        guard let stream = InputStream(fileAtPath: file) else { return [] }
        do {
        let csv = try CSVReader(stream: stream, delimiter: ";")
            guard let headerRow = csv.next() else { return [] }
            var translations: [[String: String]] = []
            for column in headerRow[1...] where column.characters.count > 0 {
                translations.append(["language": column])
            }
            while let row = csv.next() {
                guard let rowVariable = row.first else { continue }
                for (index, column) in row[1...].enumerated() {
                    if column.characters.count > 0 && index < translations.count  {
                        translations[index][rowVariable] = column
                    }
                }
            }
            return translations
        } catch {
            consoleIO.writeMessage(error.localizedDescription, to: .error)
        }
        return []
    }
    
    /**
     Creates translation files in current directory.
     
     - Parameters:
         - translations: Array of hashmap that contains the translations.
     */
    private func hashmapToStrings(translations: [[String: String]]) {
        let citation = [UInt8]("\"".utf8)
        let endCitationEquals = [UInt8]("\" = \"".utf8)
        let endRow = [UInt8]("\";\n".utf8)
        for translation in translations {
            guard let language = translation["language"], let outputStream = OutputStream(toFileAtPath: "\(language).strings", append: false) else { continue }
            outputStream.open()
            for (key, value) in translation {
                //write "
                outputStream.write(citation, maxLength: citation.count)
                //write key
                let keyData = [UInt8](key.utf8)
                outputStream.write(keyData, maxLength: keyData.count)
                //write " = "
                outputStream.write(endCitationEquals, maxLength: endCitationEquals.count)
                //write value
                let valueData = [UInt8](value.utf8)
                outputStream.write(valueData, maxLength: valueData.count)
                //write ";
                outputStream.write(endRow, maxLength: endRow.count)
            }
            outputStream.close()
        }
    }
    
    /**
     Creates translation files in current directory.
     
     - Parameters:
         - from: Path to base strings file to copy all lines and replaces values for keys that is found in the template. Formatting, comments and other text from base file will be copied.
         - translations: Array of hashmap that contains the translations.
     */
    func hashmapToStrings(from template: String, translations: [[String: String]]) {
        do {
            //Pattern for matching keys and values in template
            let regexPattern = "\"(.*)\" = \"(.*)\";"
            let regex = try NSRegularExpression(pattern: regexPattern)
            for translation in translations {
                //Ensure languge is present and createn of outputstream and reader
                guard let language = translation["language"], let outputStream = OutputStream(toFileAtPath: "\(language).strings", append: false), let streamReader = StreamReader(path: template) else { return }                
                outputStream.open()
                //Read each line from template
                while let line = streamReader.nextLine() {
                    let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))
                    //If no matches found just write line to destination file
                    if matches.count <= 0 {
                        let encodedDataArray = [UInt8]("\(line)\n".utf8)
                        outputStream.write(encodedDataArray, maxLength: encodedDataArray.count)
                    } else {
                        //Ensure theres a match for the groups (whole match + 2 groups), get key range, value range from line and value from translation
                        if let checkingResult = matches.first, checkingResult.numberOfRanges >= 3, let keyRange = Range(checkingResult.range(at: 1), in: line), let valueRange = Range(checkingResult.range(at: 2), in: line), let value = translation[String(line[keyRange])] {
                            //Copy template line and insert translation
                            let translatedLine = line.replacingCharacters(in: valueRange, with: value) + "\n"
                            //Encode and write line to destination file
                            let encodedDataArray = [UInt8](translatedLine.utf8)
                            outputStream.write(encodedDataArray, maxLength: encodedDataArray.count)
                        }
                    }
                }
                outputStream.close()
            }
        } catch let error {
            consoleIO.writeMessage(error.localizedDescription, to: .error)            
        }
    }

}
