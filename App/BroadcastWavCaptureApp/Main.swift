//
//  BroadcastWavCaptureApp.swift
//  BroadcastWavCaptureApp
//
//  Created by Naruki Chigira on 2024/12/22.
//

import SwiftUI

let store = UserDefaults(suiteName: "group.com.example.broadcast_wav_capture")

@main
struct Main: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
            }
        }
    }
}
