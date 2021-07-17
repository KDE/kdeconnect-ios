//
//  DocumentPickerView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-07-16.
//

import SwiftUI
import UIKit

// DocumentPicker() is a system modal pop-up style picker that allows the user to pick a file
// from the device and returns the URL of that file as a Bindable variable
struct DocumentPicker: UIViewControllerRepresentable {
    @Binding var fileContentData: URL?
    
    func makeCoordinator() -> DocumentPickerCoordinator {
        return DocumentPickerCoordinator(fileContentData: $fileContentData)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<DocumentPicker>) -> UIDocumentPickerViewController {
        let controller: UIDocumentPickerViewController
        controller = UIDocumentPickerViewController(forOpeningContentTypes: [.text], asCopy: true)
        controller.delegate = context.coordinator
        return controller
    }
        
        func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: UIViewControllerRepresentableContext<DocumentPicker>) {}
}

class DocumentPickerCoordinator: NSObject, UIDocumentPickerDelegate, UINavigationControllerDelegate {
    @Binding var fileContentData: URL?
    
    init(fileContentData: Binding<URL?>) {
        _fileContentData = fileContentData
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        fileContentData = urls[0]
    }
}
