//
//  Item.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import Foundation

struct Item: Identifiable {
    let url: URL

    var id: String {
        url.path()
    }
}
