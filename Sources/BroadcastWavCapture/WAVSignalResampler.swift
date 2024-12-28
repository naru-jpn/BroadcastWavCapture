//
//  WAVSignalResampler.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/27.
//

import Accelerate
import CoreMedia

public enum WAVSignalResamplerError: Error {
    case failedToExecuteFunction(String)
    case failedToGetProperty(String)
}

public class WAVSignalResampler {
    private struct Source {
        let sampleBuffer: CMSampleBuffer
        let sampleRate: Int
        let numSamples: Int

        init(sampleBuffer: CMSampleBuffer) {
            self.sampleBuffer = sampleBuffer
            self.numSamples = sampleBuffer.numSamples
            guard let sampleRate = CMSampleBufferGetFormatDescription(sampleBuffer)?.audioStreamBasicDescription?.mSampleRate else {
                fatalError("Failed to get sample rate from CMSampleBuffer.")
            }
            self.sampleRate = Int(sampleRate)
        }
    }

    private class Buffers {
        private var indexInFlight: Int = 0
        private let countInFlight: Int

        init(countInFlight: Int) {
            self.countInFlight = countInFlight
        }

        var interpolation: UnsafeMutableBufferPointer<Float> = .init(start: nil, count: 0)
        var intermediate: UnsafeMutableBufferPointer<Float> = .init(start: nil, count: 0)
        var outputs: [UnsafeMutableBufferPointer<Int16>] = [.init(start: nil, count: 0)]

        var currentIndexInFlight: Int {
            indexInFlight % countInFlight
        }

        var currentOutbutBuffer: UnsafeMutableBufferPointer<Int16> {
            outputs[currentIndexInFlight]
        }

        func updateBufferLengthIfNeeded(countSourceSignals: Int, countOutputSignals: Int) {
            let maxCountSignals = max(countSourceSignals, countOutputSignals)

            if countOutputSignals != interpolation.count, countOutputSignals > 0 {
                self.interpolation = .init(start: .allocate(capacity: countOutputSignals), count: countOutputSignals)
                if let address = self.interpolation.baseAddress {
                    vDSP_vgen([0], [Float(countOutputSignals - 1)], address, 1, vDSP_Length(countOutputSignals))
                }
            }
            if maxCountSignals != intermediate.count {
                self.intermediate = .init(start: .allocate(capacity: maxCountSignals), count: maxCountSignals)
            }
            if let output = outputs.first, countOutputSignals != output.count {
                self.outputs = (0..<countInFlight).map { _ in
                    .init(start: .allocate(capacity: countOutputSignals), count: countOutputSignals)
                }
            }
        }

        func incrementIndexInFlight() {
            indexInFlight += 1
        }
    }

    public let countInFlightBuffers: Int

    private lazy var buffers = { Buffers(countInFlight: countInFlightBuffers) }()

    public init(countInFlightBuffers: Int = 1) {
        guard countInFlightBuffers > 0 else {
            fatalError("Invalid countInFlightBuffers is applied (should be countInFlightBuffers > 0).")
        }
        self.countInFlightBuffers = countInFlightBuffers
    }

    /// Resample audio signals for arbitrary sample rate 1-channel audio
    ///
    /// - returns: Data with Int16 array
    public func resample(signalsOf sampleBuffer: CMSampleBuffer, sampleRate: Int) throws -> Data {
        defer {
            buffers.incrementIndexInFlight()
        }

        let source = Source(sampleBuffer: sampleBuffer)
        let resampledCount = Int(source.numSamples * sampleRate / source.sampleRate)
        buffers.updateBufferLengthIfNeeded(countSourceSignals: source.numSamples, countOutputSignals: resampledCount)

        let audioBuffer = try getAudioBuffer(from: sampleBuffer)

        // Swap bytes if input signals are big-endian
        let isBigEndian = try isBigEndian(sampleBuffer)
        if isBigEndian {
            let width = audioBuffer.mDataByteSize / UInt32(MemoryLayout<Int16>.size)
            var image = vImage_Buffer(data: audioBuffer.mData, height: 1, width: vImagePixelCount(width), rowBytes: Int(audioBuffer.mDataByteSize))
            vImageByteSwap_Planar16U(&image, &image, vImage_Flags(kvImageNoFlags))
        }
        guard let audioBufferInt16 = audioBuffer.mData?.bindMemory(to: Int16.self, capacity: source.numSamples) else {
            fatalError("Failed to bind memory of audio buffer.")
        }

        let outputBuffer = buffers.currentOutbutBuffer
        guard let output = outputBuffer.baseAddress else {
            throw WAVSignalResamplerError.failedToGetProperty("Addresses for resampling")
        }

        guard let intermediate = buffers.intermediate.baseAddress,
              let interpolation = buffers.interpolation.baseAddress else {
            throw WAVSignalResamplerError.failedToGetProperty("Addresses for resampling")
        }

        let channels = vDSP_Stride(audioBuffer.mNumberChannels)
        let inputLength = vDSP_Length(source.numSamples)
        let outputLength = vDSP_Length(resampledCount)
        let needsInterpolate = resampledCount != sampleBuffer.numSamples

        vDSP_vflt16(audioBufferInt16, channels, intermediate, 1, inputLength)
        if needsInterpolate {
            vDSP_vlint(intermediate, interpolation, 1, intermediate, 1, outputLength, inputLength)
        }
        vDSP_vfix16(intermediate, 1, output, 1, outputLength)

        return Data(buffer: outputBuffer)
    }

    private func getAudioBuffer(from sampleBuffer: CMSampleBuffer) throws -> AudioBuffer {
        var audioBufferList = AudioBufferList()
        var blockBufferOut: CMBlockBuffer?
        let status: OSStatus = CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
            sampleBuffer,
            bufferListSizeNeededOut: nil,
            bufferListOut: &audioBufferList,
            bufferListSize: Int(MemoryLayout<AudioBufferList>.size),
            blockBufferAllocator: kCFAllocatorDefault,
            blockBufferMemoryAllocator: kCFAllocatorDefault,
            flags: UInt32(kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment),
            blockBufferOut: &blockBufferOut
        )
        guard status == noErr else {
            throw WAVSignalResamplerError.failedToExecuteFunction("CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer")
        }
        guard blockBufferOut != nil else {
            throw WAVSignalResamplerError.failedToGetProperty("blockBufferOut")
        }
        return try withUnsafePointer(to: &audioBufferList.mBuffers) {
            let audioBuffers = UnsafeBufferPointer<AudioBuffer>(start: $0, count: Int(audioBufferList.mNumberBuffers))
            guard let audioBuffer = audioBuffers.first else {
                throw WAVSignalResamplerError.failedToGetProperty("AudioBuffer")
            }
            return audioBuffer
        }
    }

    private func isBigEndian(_ sampleBuffer: CMSampleBuffer) throws -> Bool {
        guard let formatDescription = sampleBuffer.formatDescription,
                let basicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription)?.pointee else {
            throw WAVSignalResamplerError.failedToGetProperty("StreamBasicDescription")
        }
        return kLinearPCMFormatFlagIsBigEndian == (basicDescription.mFormatFlags & kLinearPCMFormatFlagIsBigEndian)
    }
}
