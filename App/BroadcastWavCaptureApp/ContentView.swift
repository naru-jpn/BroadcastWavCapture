//
//  ContentView.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import AppGroupFiles
import SwiftUI

struct ContentView: View {
    private let files = AppGroupFiles()

    var body: some View {
        ItemList(directory: files.directory, files: files)
            .navigationTitle("Root")
    }
}

#Preview {
    ContentView()
}
