//
//  WAVTests.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import Foundation
import Testing
@testable import BroadcastWavCapture

@Suite
struct WAVBinaryFormatTests {
    let url = URL(string: "localhost://")!

    @Test(arguments: [0, 8, 10_000])
    func RIFFHeaderChunk(_ _fileSize: UInt32) {
        let data = WAV.RIFFHeader(fileSize: _fileSize).data

        let mark = String.init(data: data.subdata(in: Range(0...3)), encoding: .utf8)
        #expect(mark == "RIFF")

        let fileSize = data.withUnsafeBytes { $0.baseAddress!.advanced(by: 4).load(as: UInt32.self) }
        #expect(fileSize == _fileSize)

        let fileType = String.init(data: data.subdata(in: Range(8...11)), encoding: .utf8)
        #expect(fileType == "WAVE")
    }

    @Test(arguments: [44_100, 48_000])
    func formatChunk(_ _sampleRate: UInt32) {
        let data = WAV.Format(sampleRate: _sampleRate).data

        let mark = String.init(data: data.subdata(in: Range(0...3)), encoding: .utf8)
        #expect(mark == "fmt ")

        let size = data.withUnsafeBytes { $0.baseAddress!.advanced(by: 4).load(as: UInt32.self) }
        #expect(size == 16)

        let format = data.withUnsafeBytes { $0.baseAddress!.advanced(by: 8).load(as: UInt16.self) }
        #expect(format == 1)

        let numChannels = data.withUnsafeBytes { $0.baseAddress!.advanced(by: 10).load(as: UInt16.self) }
        #expect(numChannels == 1)

        let sampleRate = data.withUnsafeBytes { $0.baseAddress!.advanced(by: 12).load(as: UInt32.self) }
        #expect(sampleRate == _sampleRate)

        let byteRate = data.withUnsafeBytes { $0.baseAddress!.advanced(by: 16).load(as: UInt32.self) }
        #expect(byteRate == (_sampleRate * 1 * (16 / 8)))

        let blockAlign = data.withUnsafeBytes { $0.baseAddress!.advanced(by: 20).load(as: UInt16.self) }
        #expect(blockAlign == 2)

        let bitsPerSample = data.withUnsafeBytes { $0.baseAddress!.advanced(by: 22).load(as: UInt16.self) }
        #expect(bitsPerSample == 16)
    }

    @Test(arguments: [0, 8, 10_000])
    func dataHeader(_ _dataSize: UInt32) {
        let data = WAV.DataHeader(dataSize: _dataSize).data

        let mark = String.init(data: data.subdata(in: Range(0...3)), encoding: .utf8)
        #expect(mark == "data")

        let dataSize = data.withUnsafeBytes { $0.baseAddress!.advanced(by: 4).load(as: UInt32.self) }
        #expect(dataSize == _dataSize)
    }
}
