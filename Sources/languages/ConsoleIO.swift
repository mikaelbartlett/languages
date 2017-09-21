//
//  StreamReader.swift
//  languagesPackageDescription
//
//  Solution used from https://www.raywenderlich.com/163134/command-line-programs-macos-tutorial-2
//

import Foundation

enum OutputType {
  case error
  case standard
}

class ConsoleIO {
    func writeMessage(_ message: String, to outputType: OutputType = .standard) {
        switch outputType {
        case .standard:
            print("\(message)")
        case .error:
            fputs("Error: \(message)\n", stderr)
        }
    }

    func printUsage() {
        let executableName = (CommandLine.arguments[0] as NSString).lastPathComponent

        writeMessage("usage:")
        writeMessage("\(executableName) --csv {filename} --strings {filename}")
        writeMessage("or")
        writeMessage("\(executableName) -h to show usage information")
    }
}
