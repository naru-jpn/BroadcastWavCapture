//
//  ItemList.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import AppGroupAccess
import BroadcastWavCapture
import Combine
import SwiftUI

struct ItemList: View {
    @State var title: String
    @State var items: [Item]

    @State var isShowingWavFile: Bool = false
    @State var selectedWavFile: WAV.File? {
        didSet {
            isShowingWavFile = true
        }
    }

    @AppStorage("isBroadcasting", store: store) var isBroadcasting: Bool?

    private let directory: URL
    private let fileSystem: AppGroup.FileSystem

    init(directory: URL, fileSystem: AppGroup.FileSystem) {
        title = fileSystem.fileName(at: directory)
        items = fileSystem.files(at: directory).map(Item.init(url:))
        self.directory = directory
        self.fileSystem = fileSystem
    }

    var body: some View {
        List(items) { item in
            if fileSystem.isDirectory(at: item.url) {
                NavigationLink(
                    destination: {
                        ItemList(directory: item.url, fileSystem: fileSystem)
                    },
                    label: {
                        Text(fileSystem.fileName(at: item.url))
                    }
                )
            } else {
                HStack(spacing: 12) {
                    Text(fileSystem.fileName(at: item.url))
                    Button(
                        action: {
                            share(items: [item.url])
                        },
                        label: {
                            Image(systemName: "square.and.arrow.up")
                        }
                    )
                    .buttonStyle(.borderless)
                    Spacer()
                    if let wav = item.wav {
                        Button(
                            action: {
                                self.selectedWavFile = wav
                            },
                            label: {
                                Image(systemName: "info.circle")
                            }
                        )
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .navigationTitle(title)
        .alert(
            "Information of WAV File",
            isPresented: $isShowingWavFile,
            presenting: selectedWavFile,
            actions: { wav in
                Button("OK") {}
            },
            message: { wav in
                Text(wav.info())
                    .lineLimit(0)
            }
        )
        .onReceive(self.isBroadcasting.publisher) { isBroadcasting in
            let items = fileSystem.files(at: directory).map(Item.init(url:))
            if !isBroadcasting, self.items != items {
                self.items = items
            }
        }
    }

    @discardableResult
    func share(
        items: [Any],
        excludedActivityTypes: [UIActivity.ActivityType]? = nil
    ) -> Bool {
        guard let source = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController else {
            return false
        }
        let vc = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        vc.excludedActivityTypes = excludedActivityTypes
        vc.popoverPresentationController?.sourceView = source.view
        source.present(vc, animated: true)
        return true
    }
}
