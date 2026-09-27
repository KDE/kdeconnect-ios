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

@_implementationOnly import UniformTypeIdentifiers

public struct MediaTypeOptions: OptionSet {
    public let rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    /// Only Live Photos.
    public static let livePhotos = MediaTypeOptions(rawValue: 1 << 0)
    /// Images, including Live Photos.
    public static let images: MediaTypeOptions = [MediaTypeOptions(rawValue: 1 << 1), livePhotos]
    /// Only videos.
    public static let videos = MediaTypeOptions(rawValue: 1 << 2)
    
    /// All media types.
    public static let all: MediaTypeOptions = [.images, .videos]
    
    /// All uniform type identifiers for contained media types.
    internal var typeIdentifiers: [UTType] {
        var types = [UTType]()
        if contains(.images) {
            types += [.heic, .heif, .image]
        } else if contains(.livePhotos) {
            types += [.livePhoto, .heic]
        }
        if contains(.videos) {
            types.append(.audiovisualContent)
        }
        return types
    }
}
