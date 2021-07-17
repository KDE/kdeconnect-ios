//
//  DocumentPickerView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-07-16.
//

import SwiftUI
import UIKit

// DocumentPicker() is a system modal pop-up style picker that allows the user to pick a file
// from the device and returns the URLs of those files as a Bindable Array of URLs
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var chosenFileURLs: [URL]?
    
    func makeCoordinator() -> DocumentPickerCoordinator {
        return DocumentPickerCoordinator(chosenFileURLs: $chosenFileURLs)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let controller: UIDocumentPickerViewController
        controller = UIDocumentPickerViewController(forOpeningContentTypes: [.text], asCopy: true)
        
        // This allows the "browse" section to have the select feature, but not the "recent" section
        controller.allowsMultipleSelection = true
        controller.delegate = context.coordinator
        return controller
    }
        
        func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {}
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    @Binding var chosenFileURLs: [URL]?
    
    init(chosenFileURLs: Binding<[URL]?>) {
        _chosenFileURLs = chosenFileURLs
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        chosenFileURLs = urls
    }
}
