//
//  ContentView.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import AppGroupAccess
import SwiftUI

struct ContentView: View {
    private let fileSystem: AppGroup.FileSystem = AppGroup(securityApplicationGroupIdentifier: "group.com.example.broadcast_wav_capture").fileSystem

    var body: some View {
        ItemList(directory: directory, fileSystem: fileSystem)
    }

    private var directory: URL {
        fileSystem.directory
            .appending(component: "wavs", directoryHint: .isDirectory)
    }
}
