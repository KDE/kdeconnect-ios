//
//  AppSettingsView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/12.
//

#if os(macOS)

import SwiftUI

enum AppIcon: RawRepresentable, CaseIterable {
    case `default`
    case classic
    case roundedRectangle
    
    init?(rawValue: String?) {
        switch rawValue {
        case "Mac-AppIcon-Classic":
            self = .classic
        case "Mac-AppIcon-RoundedRectangle":
            self = .roundedRectangle
        default:
            self = .default
        }
    }
    
    var rawValue: String? {
        switch self {
        case .default:
            return "Mac-AppIcon"
        case .classic:
            return "Mac-AppIcon-Classic"
        case .roundedRectangle:
            return "Mac-AppIcon-RoundedRectangle"
        }
    }
    
    var name: Text {
        switch self {
        case .default:
            return Text("Default")
        case .classic:
            return Text("Classic")
        case .roundedRectangle:
            return Text("Rounded Rectangle")
        }
    }
}

struct AppSettingsView: View {
    @EnvironmentObject var settings: KdeConnectSettings
    @Binding var chosenTheme: ColorScheme?
    private let themes: [ColorScheme?] = [nil, .light, .dark]
    @Binding var appIcon: AppIcon
    @State private var appIconName: String

    init(chosenTheme: Binding<ColorScheme?>, appIcon: Binding<AppIcon>) {
        self._chosenTheme = chosenTheme
        self._appIcon = appIcon
        self.appIconName = appIcon.wrappedValue.rawValue ?? "AppIcon"
    }
    
    var body: some View {
        VStack {
            HStack {
                Picker(selection: $chosenTheme, label: Text("App Theme:")) {
                    ForEach(themes, id: \.self) { theme in
                        switch theme {
                        case .light:
                            Text("Light")
                        case .dark:
                            Text("Dark")
                        default:
                            Text("Default")
                        }
                    }
                }
                .pickerStyle(RadioGroupPickerStyle())
                .horizontalRadioGroupLayout()
                Spacer()
            }
            HStack {
                Picker(selection: $appIconName, label: Text("App Icon:")) {
                    Text("Default").tag("Mac-AppIcon")
                    Text("Classic").tag("Mac-AppIcon-Classic")
                    Text("Rounded Rectangle").tag("Mac-AppIcon-RoundedRectangle")
                }
                .pickerStyle(RadioGroupPickerStyle())
                .horizontalRadioGroupLayout()
                .onChange(of: appIconName) { iconName in
                    settings.appIcon = AppIcon(rawValue: (iconName == "Mac-AppIcon" ? nil : iconName))!
                    NSApplication.shared.applicationIconImage = NSImage(named: appIconName)
                }
                Spacer()
            }
            HStack {
                Text("Preview: ")
                Image(nsImage: NSImage(named: appIconName)!)
                Spacer()
            }
        }.padding(.all)
    }
}

struct AppSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        AppSettingsView(chosenTheme: .constant(nil), appIcon: .constant(AppIcon(rawValue: nil)!))
    }
}

#endif
