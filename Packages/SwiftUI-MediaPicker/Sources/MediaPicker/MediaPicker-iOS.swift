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

#if os(iOS)
import SwiftUI
import struct PhotosUI.PHPickerResult
@_implementationOnly import UniformTypeIdentifiers
@_implementationOnly import struct AVFoundation.AVError
@_implementationOnly import os

private func OSLog(category: String) -> os.OSLog {
#if DEBUG
    return OSLog(subsystem: "dev.uwapp.MediaPicker", category: category)
#else
    return .disabled
#endif
}

public extension View {
    /// Presents a system interface for allowing the user to import an existing
    /// media.
    ///
    /// In order for the interface to appear, `isPresented` must be `true`. When
    /// the operation is finished, `isPresented` will be set to `false` before
    /// `onCompletion` is called. If the user cancels the operation,
    /// `isPresented` will be set to `false` and `onCompletion` will not be
    /// called.
    ///
    /// - Note: Changing `allowedMediaTypes` while the media importer is
    ///   presented will have no immediate effect, however will apply the next
    ///   time it is presented.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to whether the interface should be shown.
    ///   - allowedMediaTypes: The list of supported media types which can
    ///     be imported.
    ///   - onCompletion: A callback that will be invoked when the operation has
    ///     succeeded or failed.
    ///   - result: A `Result` indicating whether the operation succeeded or
    ///     failed.
    func mediaImporter(
        isPresented: Binding<Bool>,
        allowedMediaTypes: MediaTypeOptions,
        onCompletion: @escaping (Result<URL, Error>) -> Void
    ) -> some View {
        self.mediaImporter(
            isPresented: isPresented,
            allowedMediaTypes: allowedMediaTypes,
            onCompletion: onCompletion,
            loadingOverlay: DefaultLoadingOverlay.init
        )
    }

    func mediaImporter<LoadingOverlay: View>(
        isPresented: Binding<Bool>,
        allowedMediaTypes: MediaTypeOptions,
        onCompletion: @escaping (Result<URL, Error>) -> Void,
        @ViewBuilder loadingOverlay: @escaping (Progress) -> LoadingOverlay
    ) -> some View {
        self.mediaImporter(
            isPresented: isPresented,
            allowedMediaTypes: allowedMediaTypes,
            allowsMultipleSelection: false,
            onCompletion: { result in
                onCompletion(result.map { $0.first! })
            },
            loadingOverlay: loadingOverlay
        )
    }
    
    /// Presents a system interface for allowing the user to import multiple
    /// medium.
    ///
    /// In order for the interface to appear, `isPresented` must be `true`. When
    /// the operation is finished, `isPresented` will be set to `false` before
    /// `onCompletion` is called. If the user cancels the operation,
    /// `isPresented` will be set to `false` and `onCompletion` will not be
    /// called.
    ///
    /// - Note: Changing `allowedMediaTypes` or `allowsMultipleSelection`
    ///   while the media importer is presented will have no immediate effect,
    ///   however will apply the next time it is presented.
    ///
    /// - Parameters:
    ///   - isPresented: A binding to whether the interface should be shown.
    ///   - allowedMediaTypes: The list of supported media types which can
    ///     be imported.
    ///   - allowsMultipleSelection: Whether the importer allows the user to
    ///     select more than one media to import.
    ///   - onCompletion: A callback that will be invoked when the operation has
    ///     succeeded or failed.
    ///   - result: A `Result` indicating whether the operation succeeded or
    ///     failed.
    func mediaImporter(
        isPresented: Binding<Bool>,
        allowedMediaTypes: MediaTypeOptions,
        allowsMultipleSelection: Bool,
        onCompletion: @escaping (Result<[URL], Error>) -> Void
    ) -> some View {
        self.mediaImporter(
            isPresented: isPresented,
            allowedMediaTypes: allowedMediaTypes,
            allowsMultipleSelection: allowsMultipleSelection,
            onCompletion: onCompletion,
            loadingOverlay: DefaultLoadingOverlay.init
        )
    }
    
    func mediaImporter<LoadingOverlay: View>(
        isPresented: Binding<Bool>,
        allowedMediaTypes: MediaTypeOptions,
        allowsMultipleSelection: Bool,
        onCompletion: @escaping (Result<[URL], Error>) -> Void,
        @ViewBuilder loadingOverlay: @escaping (Progress) -> LoadingOverlay
    ) -> some View {
        let progress = Progress()
        return self.mediaImporter(
            isPresented: isPresented,
            allowedMediaTypes: allowedMediaTypes,
            allowsMultipleSelection: allowsMultipleSelection
        ) { (result: Result<[PHPickerResult], Error>) in
            switch result {
            case .success(let phPickerResults):
                importAsURLs(phPickerResults,
                             allowedMediaTypes: allowedMediaTypes,
                             progress: progress) { result in
                    isPresented.wrappedValue = false
                    onCompletion(result)
                }
            case .failure(let error):
                isPresented.wrappedValue = false
                onCompletion(.failure(error))
            }
        } loadingOverlay: {
            loadingOverlay(progress)
        }
    }
}

fileprivate struct DefaultLoadingOverlay: View {
    let progress: Progress
    var body: some View {
        NavigationView {
            ProgressView(progress)
                .padding()
                .navigationTitle("Importing Media...")
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

fileprivate func importAsURLs(_ phPickerResults: [PHPickerResult],
                              allowedMediaTypes: MediaTypeOptions,
                              progress: Progress,
                              onCompletion: @escaping (Result<[URL], Error>) -> Void) {
    let log = OSLog(category: "imageURLs")
    let signpostID = OSSignpostID(log: log, object: phPickerResults as NSArray)
    os_signpost(.begin, log: log, name: "imageURLs task group", signpostID: signpostID,
                "Loading %d results", phPickerResults.count)
    
    var imageURLs = [URL?](repeating: nil, count: phPickerResults.count)
    var errors = [Error]()
    var finishedCount = 0
    let queue = DispatchQueue(label: UUID().uuidString)
    progress.totalUnitCount = Int64(phPickerResults.count)
    progress.completedUnitCount = 0
    
    func recordResult(_ result: Result<URL, Error>, for index: Int) {
        queue.sync {
            finishedCount += 1

            switch result {
            case .success(let url):
                os_signpost(.event, log: log, name: "imageURLs add url", signpostID: signpostID,
                            "Adding %d out of %d results, url: %{public}@",
                            finishedCount, phPickerResults.count, url.path)
                imageURLs[index] = url
            case .failure(let error):
                os_signpost(.event, log: log, name: "imageURLs add url", signpostID: signpostID,
                            "Adding %d out of %d results, error: %{public}@",
                            finishedCount, phPickerResults.count, error.localizedDescription)
                errors.append(error)
            }
            
            guard finishedCount == phPickerResults.count else {
                return
            }
            
            let resultImageURLs = imageURLs.compactMap { $0 }
            if errors.isEmpty {
                os_signpost(.end, log: log, name: "imageURLs task group", signpostID: signpostID,
                            "success")
                onCompletion(.success(resultImageURLs))
            } else {
                os_signpost(.end, log: log, name: "imageURLs task group", signpostID: signpostID,
                            "errored: %d", errors.count)
                onCompletion(.failure(MediaPickerErrors.imageURL(resultImageURLs, errors: errors)))
            }
        }
    }

    os_signpost(.begin, log: log, name: "imageURLs add task", signpostID: signpostID,
                "Adding %d tasks", phPickerResults.count)
pickerResultsLoop:
    for (index, result) in phPickerResults.enumerated() {
        let provider = result.itemProvider
        // TOOD: investigate should we instead use/consider
        // provider.registeredTypeIdentifiers
        for type in allowedMediaTypes.typeIdentifiers {
            if provider.hasItemConformingToTypeIdentifier(type.identifier) {
                os_signpost(.event, log: log, name: "imageURLs add task", signpostID: signpostID,
                            "Adding %d out of %d tasks: '%{public}@' of type %{public}@",
                            index + 1, phPickerResults.count, provider.suggestedName ?? "", type.identifier)
                
                let signpostID = OSSignpostID(log: log, object: provider)
                os_signpost(.begin, log: log, name: "fileURL loadFileRepresentation", signpostID: signpostID,
                            "%{public}@", provider.suggestedName ?? "")
                // https://developer.apple.com/forums/thread/652496
                let loadingProgress = provider.loadFileRepresentation(forTypeIdentifier: type.identifier) { url, error in
                    guard let src = url else {
                        os_signpost(.end, log: log, name: "fileURL loadFileRepresentation", signpostID: signpostID,
                                    "errored, no src url")
                        return recordResult(.failure(error!), for: index)
                    }
                    os_signpost(.end, log: log, name: "fileURL loadFileRepresentation", signpostID: signpostID)
                    
                    // Because the src/url will be deleted once we return,
                    // will copy the stored image to a different temp url.
                    let dst = FileManager.default.temporaryDirectory
                        .appendingPathComponent(src.lastPathComponent)
                    os_signpost(.begin, log: log, name: "fileURL copy", signpostID: signpostID,
                                "fileURL copy from %@ to %@", src.path, dst.path)
                    if FileManager.default.fileExists(atPath: dst.path) {
                        os_signpost(.end, log: log, name: "fileURL copy", signpostID: signpostID,
                                    "already exists")
                        return recordResult(.success(dst), for: index)
                    } else {
                        do {
                            try FileManager.default.copyItem(at: src, to: dst)
                            os_signpost(.end, log: log, name: "fileURL copy", signpostID: signpostID,
                                        "copied")
                            return recordResult(.success(dst), for: index)
                        } catch {
                            os_signpost(.end, log: log, name: "fileURL copy", signpostID: signpostID,
                                        "errored: %{public}d", error.localizedDescription)
                            return recordResult(.failure(error), for: index)
                        }
                    }
                }
                progress.addChild(loadingProgress, withPendingUnitCount: 1)
                continue pickerResultsLoop
            }
        }
        os_signpost(.event, log: log, name: "imageURLs add task", signpostID: signpostID,
                    "Adding %d out of %d tasks: '%{public}@' can't be loaded, only has %{public}@",
                    index + 1, phPickerResults.count, provider.suggestedName ?? "", provider.registeredTypeIdentifiers)
        recordResult(.failure(MediaPickerErrors.missingFileRepresentation), for: index)
    }
    os_signpost(.end, log: log, name: "imageURLs add task", signpostID: signpostID)
}
#endif
