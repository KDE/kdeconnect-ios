//
//  SettingsListCellView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-17.
//

import SwiftUI

struct SettingsListCellView: View {
    let entryTitle: String
    @State var entryDescription: String
    
    var body: some View {
        Button(action: {
            
        }, label: {
            HStack {
                Text(entryTitle)
                    .padding(.leading, 15)
                Spacer()
                Text(entryDescription)
                    .padding(.trailing, 15)
            }
        })
    }
}

struct SettingsListCellView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsListCellView(entryTitle: "Device Name", entryDescription: "iPhone 7")
    }
}








//struct SettingsChosenThemeView: View {
//    @Binding var chosenTheme: AppTheme
//
//    @State var isSystemDefault: Bool = false
//    @State var isLight: Bool = false
//    @State var isDark: Bool = false
//
//    var body: some View {
//        List {
//            Toggle("System Default", isOn: $isSystemDefault)
//            Toggle("Light", isOn: $isLight)
//            Toggle("Dark", isOn: $isDark)
//        }.onAppear {
//            switch chosenTheme {
//                case .systemDefault: isSystemDefault = true
//                case .light: isLight = true
//                case .dark: isDark = true
//            }
//        }.onDisappear {
//
//        }
//    }
//}
//
//struct SettingsChosenThemeView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsChosenThemeView(chosenTheme: .constant(.systemDefault))
//    }
//}
