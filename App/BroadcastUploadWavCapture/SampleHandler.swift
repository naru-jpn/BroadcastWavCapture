//
//  SampleHandler.swift
//  BroadcastUploadWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import Accelerate
import AppGroupAccess
import BroadcastWavCapture
import ReplayKit
import SwiftUI

let store = UserDefaults(suiteName: "group.com.example.broadcast_wav_capture")

class SampleHandler: RPBroadcastSampleHandler {
    private var directoryName: String = ""
    private var wavWriterApp: WAVWriter?
    private var wavWriterMic: WAVWriter?
    private lazy var fileSystem: AppGroup.FileSystem = { AppGroup(securityApplicationGroupIdentifier: "group.com.example.broadcast_wav_capture").fileSystem }()

    private let resampler = WAVSignalResampler()

    @AppStorage("isBroadcasting", store: store) var isBroadcasting: Bool = false

    override func broadcastStarted(withSetupInfo setupInfo: [String : NSObject]?) {
        isBroadcasting = true
        directoryName = currentTimestamp
    }
    
    override func broadcastPaused() {
    }
    
    override func broadcastResumed() {
    }
    
    override func broadcastFinished() {
        wavWriterApp?.completeMetadata()
        wavWriterMic?.completeMetadata()
        isBroadcasting = false
    }

    override func finishBroadcastWithError(_ error: any Error) {
        isBroadcasting = false
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            break
        case RPSampleBufferType.audioApp:
            let sampleRate = getSampleRate(from: sampleBuffer)
            if let wavWriterApp {
                do {
                    let data = try resampler.resample(signalsOf: sampleBuffer, sampleRate: sampleRate)
                    wavWriterApp.writeAudio(data: data)
                } catch {
                    print(error)
                }
            } else {
                wavWriterApp = WAVWriter(url: appWavURL, sampleRate: UInt32(sampleRate))
            }
            break
        case RPSampleBufferType.audioMic:
            let sampleRate = getSampleRate(from: sampleBuffer)
            if let wavWriterMic {
                do {
                    let data = try resampler.resample(signalsOf: sampleBuffer, sampleRate: sampleRate)
                    wavWriterMic.writeAudio(data: data)
                } catch {
                    print(error)
                }
            } else {
                wavWriterMic = WAVWriter(url: micWavURL, sampleRate: UInt32(sampleRate))
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
        dateFormatter.dateFormat = "yyyyMMdd_HH:mm:ss"
        return dateFormatter.string(from: Date())
    }

    private var appWavURL: URL {
        fileSystem.directory
            .appending(component: "wavs", directoryHint: .isDirectory)
            .appending(component: directoryName, directoryHint: .isDirectory)
            .appending(path: "app.wav", directoryHint: .notDirectory)
    }

    private var micWavURL: URL {
        fileSystem.directory
            .appending(component: "wavs", directoryHint: .isDirectory)
            .appending(component: directoryName, directoryHint: .isDirectory)
            .appending(path: "mic.wav", directoryHint: .notDirectory)
    }
}
