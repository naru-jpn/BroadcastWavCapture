//
//  ItemList.swift
//  BroadcastWavCapture
//
//  Created by Naruki Chigira on 2024/12/22.
//

import AppGroupFiles
import SwiftUI

struct ItemList: View {
    @State var title: String
    @State var items: [Item]

    private let files: AppGroupFiles

    init(directory: URL, files: AppGroupFiles) {
        title = files.fileName(at: directory)
        items = files.files(at: directory).map(Item.init(url:))
        self.files = files
    }

    var body: some View {
        List(items) { item in
            if files.isDirectory(at: item.url) {
                NavigationLink(
                    destination: {
                        ItemList(directory: item.url, files: files)
                    },
                    label: {
                        Text(files.fileName(at: item.url))
                    }
                )
            } else {
                Button(
                    action: {
                        share(items: [item.url])
                    },
                    label: {
                        Text(files.fileName(at: item.url))
                    }
                )
            }
        }
        .navigationTitle(title)
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
