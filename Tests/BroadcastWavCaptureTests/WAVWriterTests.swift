//
//  WAVWriterTests.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import Foundation
import Testing
@testable import BroadcastWavCapture

@Suite
final class WAVWriterTests {
    let uuid: String

    init() {
        uuid = UUID().uuidString
    }

    var url: URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appending(component: uuid, directoryHint: .isDirectory)
            .appending(component: "audio.wav", directoryHint: .notDirectory)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    @Test(arguments: [16, 1_024])
    func writeWAV(_ count: Int16) {
        let writer = WAVWriter(url: url, sampleRate: 44_100)

        do {
            #expect(try writer.fileHandle.offset() == 44)
        } catch {
            fatalError("Failed to read offset with error: \(error)")
        }

        let values: [Int16] = Array<Int16>(0..<count)
        let data = values.withUnsafeBufferPointer { Data(buffer: $0) }
        writer.writeAudio(data: data)

        do {
            #expect(try writer.fileHandle.offset() == 44 + (UInt64(count) * 2))
        } catch {
            fatalError("Failed to read offset with error: \(error)")
        }

        // update metadata for content size
        writer.completeMetadata()

        do {
            let fileHandle = try FileHandle(forReadingFrom: url)

            try fileHandle.seek(toOffset: 4)
            guard let fileSize = try fileHandle.read(upToCount: 4)?.withUnsafeBytes({ $0.baseAddress!.load(as: UInt32.self) }) else {
                fatalError("Failed to read fileSize.")
            }
            #expect(fileSize == ((44 + (UInt32(count) * 2)) - 8))

            try fileHandle.seek(toOffset: 41)
            guard let contentSize = try fileHandle.read(upToCount: 4)?.withUnsafeBytes({ $0.baseAddress!.load(as: UInt32.self) }) else {
                fatalError("Failed to read contentSize.")
            }
            #expect(contentSize == (UInt32(count) * 2))
        } catch {
            fatalError("Error occured to read size information with error: \(error)")
        }
    }
}
