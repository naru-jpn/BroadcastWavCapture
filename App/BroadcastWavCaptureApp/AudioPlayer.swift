//
//  AudioPlayer.swift
//  BroadcastWavCapture
//
//  Created by naruki.chigira on 2025/04/08.
//

import AVFoundation
import SwiftUI

struct AudioPlayerView: View {
    @StateObject private var playerManager: AudioPlayerManager

    init(audioURL: URL) {
        _playerManager = StateObject(wrappedValue: AudioPlayerManager(url: audioURL))
    }

    var body: some View {
        HStack(spacing: 10) {
            Button(action: {
                playerManager.playPause()
            }) {
                Image(systemName: playerManager.isPlaying ? "pause.fill" : "play.fill")
                    .font(.title)
            }

            Slider(
                value: Binding(
                    get: { playerManager.currentTime },
                    set: { newValue in
                        playerManager.seek(to: newValue)
                    }
                ),
                in: 0...playerManager.duration
            )

            HStack(spacing: 2) {
                Text(String(format: "%.2fs", playerManager.currentTime))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                Text("/")
                Text(String(format: "%.2fs", playerManager.duration))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
            }
        }
        .padding()
    }
}

private class AudioPlayerManager: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0

    var audioPlayer: AVAudioPlayer?
    var timer: Timer?

    init(url: URL) {
        super.init()
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.delegate = self
            currentTime = 0
        } catch {
            print("Failed to initialize AVAudioPlayer: \(error)")
        }
    }

    var duration: TimeInterval {
        return audioPlayer?.duration ?? 0
    }

    func playPause() {
        guard let player = audioPlayer else { return }
        if player.isPlaying {
            player.pause()
            isPlaying = false
            timer?.invalidate()
        } else {
            player.play()
            isPlaying = true
            startTimer()
        }
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            guard let self = self, let player = self.audioPlayer else { return }
            self.currentTime = player.currentTime
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        currentTime = 0
        player.currentTime = 0
        timer?.invalidate()
    }
}

