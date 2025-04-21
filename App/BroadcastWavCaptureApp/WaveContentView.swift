import Accelerate
import AVFoundation
import BroadcastWavCapture
import SwiftUI

struct WaveformView: View {
    @StateObject private var waveformModel = WaveformModel()
    private let url: URL
    private let file: WAV.File

    init(url: URL, file: WAV.File) {
        self.url = url
        self.file = file
    }

    var body: some View {
        VStack {
            if waveformModel.isLoading {
                ProgressView("Loading waveform...")
            } else if let error = waveformModel.error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else if waveformModel.samples.isEmpty {
                Text("No waveform data")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    GeometryReader { geometry in
                        ScrollView(.horizontal, showsIndicators: true) {
                            let contentLength = (CGFloat(waveformModel.samples.count) / CGFloat(file.fmt.sampleRate)) * geometry.size.width
                            WaveformDrawingView(samples: waveformModel.samples, sampleRate: Int(file.fmt.sampleRate), color: .blue, parentWidth: geometry.size.width)
                                .frame(width: contentLength, height: 200)
                        }
                    }
                    .frame(height: 200)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    AudioPlayerView(audioURL: url)
                }
            }
        }
        .navigationTitle("Waveform Viewer")
        .onAppear {
            try? AVAudioSession.sharedInstance().setCategory(.playback)
            try? AVAudioSession.sharedInstance().setActive(true)
            waveformModel.loadAudio(from: url, sampleRate: CGFloat(file.fmt.sampleRate))
        }
        .onDisappear() {
            try? AVAudioSession.sharedInstance().setActive(false)
        }
    }
}

private class WaveformModel: ObservableObject {
    @Published var samples: [Float] = []
    @Published var isLoading = false
    @Published var error: String?

    func loadAudio(from url: URL, sampleRate: CGFloat) {
        isLoading = true
        error = nil
        samples = []

        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else {
                return
            }

            do {
                let audioFile = try AVAudioFile(forReading: url)
                guard let buffer = AVAudioPCMBuffer(pcmFormat: audioFile.processingFormat, frameCapacity: AVAudioFrameCount(audioFile.length)) else {
                    throw NSError(domain: "WaveformModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create buffer."])
                }
                try audioFile.read(into: buffer)
                guard let channelData = buffer.floatChannelData?[0] else {
                    throw NSError(domain: "WaveformModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "No channel data."])
                }

                let samplesCount = Int(buffer.frameLength)
                var samples: [Float] = .init(repeating: 0, count: samplesCount)
                _ = samples.withUnsafeMutableBufferPointer { buffer in
                    memcpy(buffer.baseAddress, channelData, samplesCount * MemoryLayout<Float>.stride)
                }
                let maxSample = vDSP.maximum(samples)
                if maxSample > 0.0 {
                    samples = vDSP.divide(samples, maxSample)
                }
                DispatchQueue.main.async {
                    self.samples = samples
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.error = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

private struct WaveformDrawingView: View {
    let samples: [Float]
    let sampleRate: Int
    let color: Color
    let parentWidth: CGFloat

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let middle = height / 2

            let seconds = Int(samples.count / sampleRate)
            Path { path in
                for index in stride(from: 1, through: seconds, by: 1) {
                    let x = parentWidth * CGFloat(index)
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: height))
                }
            }
            .strokedPath(StrokeStyle(lineWidth: 1.0, dash: [2.0, 2.0]))
            .foregroundStyle(.gray)

            Path { path in
                let pointSpacing = parentWidth / CGFloat(sampleRate)
                let pointStride = Int(0.5 / pointSpacing)

                path.move(to: CGPoint(x: 0, y: middle))
                for index in stride(from: 0, to: samples.count, by: pointStride) {
                    let x = CGFloat(index) * pointSpacing
                    let amplitude = CGFloat(samples[index]) * (height / 2)
                    path.addLine(to: CGPoint(x: x, y: middle - amplitude))
                }
            }
            .stroke(color, lineWidth: 0.5)

            ForEach(1...seconds, id: \.self) { index in
                let x = parentWidth * CGFloat(index)
                Text("\(index)s")
                    .font(.system(.footnote, design: .rounded, weight: .bold))
                    .foregroundStyle(.gray)
                    .position(x: x - 16, y: 12)
            }
        }
    }
}
