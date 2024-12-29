//
//  WAV+File.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/29.
//

import Foundation

public enum WAVLoadError: Error {
    case invalidContentsSize
    case invalidRIFF
    case invalidFMT
    case invalidDATA
}

extension WAV {
    public struct File {
        public struct RIFF {
            /// 1-4
            public let mark = "RIFF"
            /// 5-8
            public let fileSize: UInt32
            /// 9-12
            public let fileType = "WAVE"
        }
        public struct FMT {
            /// 13-16
            public let mark: String = "fmt "
            /// 17-20
            public let size: UInt32 = 16
            /// 21-22
            public let format: UInt16 = 1
            /// 23-24
            public let numChannels: UInt16
            /// 25-28
            public let sampleRate: UInt32
            /// 29-32
            public let byteRate: UInt32
            /// 33-34
            public let blockAlign: UInt16
            /// 35-36
            public let bitsPerSample: UInt16
        }
        public struct DATA {
            /// 37-40
            public let mark: String = "data"
            /// 41-44
            public let dataSize: UInt32
        }

        public let riff: RIFF
        public let fmt: FMT
        public let data: DATA
    }
}

extension WAV.File {
    public static func load(from url: URL) throws -> Self {
        func loadRIFF(data: Data) -> RIFF? {
            let mark = String(data: data[0...3], encoding: .utf8)
            guard let fileSize = data[4...7].withUnsafeBytes({ $0.baseAddress?.load(as: UInt32.self) }) else {
                return nil
            }
            let fileType = String(data: data[8...11], encoding: .utf8)
            guard mark == "RIFF", fileType == "WAVE" else {
                return nil
            }
            return .init(
                fileSize: fileSize
            )
        }
        func loadFMT(data: Data) -> FMT? {
            let mark = String(data: data[12...15], encoding: .utf8)
            guard let size = data[16...19].withUnsafeBytes({ $0.baseAddress?.load(as: UInt32.self) }) else {
                return nil
            }
            guard let format = data[20...21].withUnsafeBytes({ $0.baseAddress?.load(as: UInt16.self) }) else {
                return nil
            }
            guard let numChannels = data[22...23].withUnsafeBytes({ $0.baseAddress?.load(as: UInt16.self) }) else {
                return nil
            }
            guard let sampleRate = data[24...27].withUnsafeBytes({ $0.baseAddress?.load(as: UInt32.self) }) else {
                return nil
            }
            guard let byteRate = data[28...31].withUnsafeBytes({ $0.baseAddress?.load(as: UInt32.self) }) else {
                return nil
            }
            guard let blockAlign = data[32...33].withUnsafeBytes({ $0.baseAddress?.load(as: UInt16.self) }) else {
                return nil
            }
            guard let bitsPerSample = data[34...35].withUnsafeBytes({ $0.baseAddress?.load(as: UInt16.self) }) else {
                return nil
            }
            guard mark == "fmt ", size == 16, format == 1 else {
                return nil
            }
            return .init(
                numChannels: numChannels,
                sampleRate: sampleRate,
                byteRate: byteRate,
                blockAlign: blockAlign,
                bitsPerSample: bitsPerSample
            )
        }
        func loadDATA(data: Data) -> DATA? {
            let mark = String(data: data[36...39], encoding: .utf8)
            guard let dataSize = data[40...43].withUnsafeBytes({ $0.baseAddress?.load(as: UInt32.self) }) else {
                return nil
            }
            guard mark == "data" else {
                return nil
            }
            return .init(
                dataSize: dataSize
            )
        }

        let data = try Data(contentsOf: url)
        guard data.count >= 43 else {
            throw WAVLoadError.invalidContentsSize
        }
        guard let riff = loadRIFF(data: data) else {
            throw WAVLoadError.invalidRIFF
        }
        guard let fmt = loadFMT(data: data) else {
            throw WAVLoadError.invalidFMT
        }
        guard let data = loadDATA(data: data) else {
            throw WAVLoadError.invalidDATA
        }
        return .init(riff: riff, fmt: fmt, data: data)
    }
}
