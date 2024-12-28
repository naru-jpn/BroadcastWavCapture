// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation

public class AppGroup {
    public class FileSystem {
        let securityApplicationGroupIdentifier: String

        init(securityApplicationGroupIdentifier: String) {
            self.securityApplicationGroupIdentifier = securityApplicationGroupIdentifier
        }

        public var directory: URL {
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: securityApplicationGroupIdentifier)!
        }

        public var rootFiles: [URL] {
            do {
                return try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            } catch {
                return []
            }
        }

        public func isDirectory(at url: URL) -> Bool {
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: url.path(), isDirectory: &isDirectory)
            return isDirectory.boolValue
        }

        public func files(at url: URL) -> [URL] {
            do {
                return try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
                    .sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
            } catch {
                return []
            }
        }

        public func fileName(at url: URL) -> String {
            url.lastPathComponent
        }
    }

    public let securityApplicationGroupIdentifier: String
    public let fileSystem: FileSystem

    public init(securityApplicationGroupIdentifier: String) {
        self.securityApplicationGroupIdentifier = securityApplicationGroupIdentifier
        self.fileSystem = FileSystem(securityApplicationGroupIdentifier: securityApplicationGroupIdentifier)
    }
}
