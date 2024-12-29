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
