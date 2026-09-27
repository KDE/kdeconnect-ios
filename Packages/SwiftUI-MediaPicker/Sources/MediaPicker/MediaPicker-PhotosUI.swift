//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftUI FoodTracker tutorial series
//
// Copyright (c) 2020-2022 AppDev@UW.edu and the SwiftUI MediaPicker authors
// Licensed under MIT License
//
// See https://github.com/UWAppDev/SwiftUI-MediaPicker/blob/main/LICENSE
// for license information
// See https://github.com/UWAppDev/SwiftUI-MediaPicker/graphs/contributors
// for the list of SwiftUI MediaPicker project authors
//
//===----------------------------------------------------------------------===//

#if canImport(PhotosUI) && os(iOS)
import SwiftUI
import PhotosUI

public extension View {
    /// - Important: You are responsible for setting `isPresented` to false.
    func mediaImporter<LoadingOverlay: View>(
        isPresented: Binding<Bool>,
        allowedMediaTypes: MediaTypeOptions,
        allowsMultipleSelection: Bool,
        onCompletion: @escaping (Result<[PHPickerResult], Error>) -> Void,
        @ViewBuilder loadingOverlay: @escaping () -> LoadingOverlay
    ) -> some View {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.selectionLimit = allowsMultipleSelection ? 0 : 1
        configuration.filter = PHPickerFilter.from(allowedMediaTypes)
        
        return sheet(isPresented: isPresented) {
            MediaPickerWrapper(
                isPresented: isPresented,
                allowedContentTypes: allowedMediaTypes.typeIdentifiers,
                configuration: configuration,
                onCompletion: onCompletion,
                makeLoadingOverlay: loadingOverlay
            )
        }
    }
}

fileprivate struct MediaPickerWrapper<LoadingOverlay: View>: View {
    @Binding var isPresented: Bool
    @State var isLoading: Bool = false
    let allowedContentTypes: [UTType]
    let configuration: PHPickerConfiguration
    let onCompletion: (Result<[PHPickerResult], Error>) -> Void
    let makeLoadingOverlay: () -> LoadingOverlay
    
    var body: some View {
        MediaPicker(
            isPresented: $isPresented,
            isLoading: $isLoading,
            allowedContentTypes: allowedContentTypes,
            configuration: configuration,
            onCompletion: onCompletion
        )
        .overlay(isLoading ? makeLoadingOverlay() : nil)
    }
}

fileprivate extension PHPickerFilter {
    static func from(_ mediaOptions: MediaTypeOptions) -> Self {
        var filters = [PHPickerFilter]()
        if mediaOptions.contains(.images) {
            filters.append(.images)
        } else if mediaOptions.contains(.livePhotos) {
            filters.append(.livePhotos)
        }
        if mediaOptions.contains(.videos) {
            filters.append(.videos)
        }
        return PHPickerFilter.any(of: filters)
    }
}

// Meet the new Photos picker
// https://developer.apple.com/wwdc20/10652
fileprivate struct MediaPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var isLoading: Bool
    let allowedContentTypes: [UTType]
    let configuration: PHPickerConfiguration
    let onCompletion: (Result<[PHPickerResult], Error>) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        let controller = PHPickerViewController(configuration: configuration)
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController,
                                context: Context) {
        // do nothing
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(for: self)
    }
    
    class Coordinator: PHPickerViewControllerDelegate {
        let coordinated: MediaPicker
        
        init(for picker: MediaPicker) {
            self.coordinated = picker
        }
        
        func picker(_ picker: PHPickerViewController,
                    didFinishPicking results: [PHPickerResult]) {
            guard !results.isEmpty else {
                coordinated.isPresented = false
                return
            }
            Task { @MainActor in
                withAnimation {
                    coordinated.isLoading = true
                }
            }
            coordinated.onCompletion(.success(results))
        }
    }
}
#endif
