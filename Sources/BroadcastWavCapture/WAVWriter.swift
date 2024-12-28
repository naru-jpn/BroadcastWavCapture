//
//  WAVMaker.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import CoreMedia

public class WAVWriter {
    public let url: URL
    public let wav: WAV
    public let fileHandle: FileHandle

    public init(url: URL, sampleRate: UInt32) {
        self.url = url
        self.wav = WAV(sampleRate: UInt32(sampleRate))

        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try self.wav.dataForEmptyWav.write(to: url)
        } catch {
            fatalError("Failed to prepare wav file with error: \(error)")
        }

        do {
            fileHandle = try FileHandle(forWritingTo: url)
            try fileHandle.seekToEnd()
        } catch {
            fatalError("Failed to prepare FileHandle to write data with error:\(error)")
        }
    }

    public func writeAudio(data: Data) {
        do {
            try fileHandle.write(contentsOf: data)
        } catch {
            fatalError("Failed to write data with error: \(error)")
        }
    }

    /// Complete metadata for content size with current written content.
    public func completeMetadata() {
        do {
            let currentOffset = try fileHandle.offset()
            // update file size
            let fileSize = {
                var littleEndian = (currentOffset - 8).littleEndian
                return Data(bytes: &littleEndian, count: 4)
            }()
            try fileHandle.seek(toOffset: 4)
            try fileHandle.write(contentsOf: fileSize)
            // updte data size
            let dataSize = {
                var littleEndian = (currentOffset - 44).littleEndian
                return Data(bytes: &littleEndian, count: 4)
            }()
            try fileHandle.seek(toOffset: 41)
            try fileHandle.write(contentsOf: dataSize)
            try fileHandle.seekToEnd()
        } catch {
            fatalError("Failed to update metadata with error: \(error)")
        }
    }
}
