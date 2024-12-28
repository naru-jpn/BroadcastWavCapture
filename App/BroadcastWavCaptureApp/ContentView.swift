//
//  ContentView.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import AppGroupAccess
import SwiftUI

struct ContentView: View {
    private let appgroup = AppGroup(securityApplicationGroupIdentifier: "group.com.example.broadcast_wav_capture")

    var body: some View {
        ItemList(directory: directory, appgroup: appgroup)
            .navigationTitle("Root")
    }

    private var directory: URL {
        appgroup.fileSystem.directory
            .appending(component: "wavs", directoryHint: .isDirectory)
    }
}

#Preview {
    ContentView()
}
