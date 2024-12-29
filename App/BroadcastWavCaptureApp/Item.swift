//
//  Item.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import Foundation
import BroadcastWavCapture

struct Item {
    let url: URL
    let wav: WAV.File?

    init(url: URL) {
        self.url = url
        self.wav = try? WAV.File.load(from: url)
    }
}

extension Item: Identifiable {
    var id: String {
        url.path()
    }
}

extension Item: Equatable {
    static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}

extension WAV.File {
    func info() -> String {
        "Number of Channels: \(fmt.numChannels)\n"
        + "Sampling Rate: \(fmt.sampleRate)\n"
        + "Byte Rate: \(fmt.byteRate)\n"
        + "Bits per Sample: \(fmt.bitsPerSample)\n"
        + "Size of Data: \(data.dataSize)\n"
        + "Estimated Audio Length: \(estimatedAudioLength)"
    }

    var estimatedAudioLength: String {
        let seconds: Int = Int(data.dataSize) / Int(fmt.byteRate)
        return seconds > 60 ? "\(seconds / 60)m\(seconds % 60)s" : "\(seconds)s"
    }
}
