//
//  SampleHandler.swift
//  BroadcastUploadWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import Accelerate
import AppGroupFiles
import BroadcastWavCapture
import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {
    private var timestamp: String = ""
    private var writerForApp: WAVWriter?
    private var writerForMic: WAVWriter?

    private let resampler = WAVSignalResampler()

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        timestamp = currentTimestamp
    }
    
    override func broadcastPaused() {
    }
    
    override func broadcastResumed() {
    }
    
    override func broadcastFinished() {
        writerForApp?.completeMetadata()
        writerForMic?.completeMetadata()
    }
    
    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            break
        case RPSampleBufferType.audioApp:
            let sampleRate = getSampleRate(from: sampleBuffer)
            if let writerForApp {
                do {
                    let data = try resampler.resample(signalsOf: sampleBuffer, sampleRate: sampleRate)
                    writerForApp.writeAudio(data: data)
                } catch {
                    print(error)
                }
            } else {
                writerForApp = WAVWriter(url: appWavURL(timestamp: timestamp), sampleRate: UInt32(sampleRate))
            }
            break
        case RPSampleBufferType.audioMic:
            let sampleRate = getSampleRate(from: sampleBuffer)
            if let writerForMic {
                do {
                    let data = try resampler.resample(signalsOf: sampleBuffer, sampleRate: sampleRate)
                    writerForMic.writeAudio(data: data)
                } catch {
                    print(error)
                }
            } else {
                writerForMic = WAVWriter(url: micWavURL(timestamp: timestamp), sampleRate: UInt32(sampleRate))
            }
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
}

// MARK: Audio

extension SampleHandler {
    func getSampleRate(from sampleBuffer: CMSampleBuffer) -> Int {
        guard let sampleRate = CMSampleBufferGetFormatDescription(sampleBuffer)?.audioStreamBasicDescription?.mSampleRate else {
            fatalError("Failed to get sample rate from CMSampleBuffer.")
        }
        return Int(sampleRate)
    }
}

// MARK: File Control

extension SampleHandler {
    private var currentTimestamp: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_H:mm:ss"
        return dateFormatter.string(from: Date())
    }

    private func appWavURL(timestamp: String) -> URL {
        AppGroupFiles().directory
            .appending(component: timestamp, directoryHint: .isDirectory)
            .appending(path: "app.wav", directoryHint: .notDirectory)
    }

    private func micWavURL(timestamp: String) -> URL {
        AppGroupFiles().directory
            .appending(component: timestamp, directoryHint: .isDirectory)
            .appending(path: "mic.wav", directoryHint: .notDirectory)
    }
}
