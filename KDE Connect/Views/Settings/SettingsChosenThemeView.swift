//
//  SettingsChosenThemeView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-19.
//

#if !os(macOS)

import SwiftUI

struct SettingsChosenThemeView: View {
    @Binding var chosenTheme: ColorScheme?
    
    var body: some View {
        Picker(selection: $chosenTheme) {
            ForEach(ColorScheme?.allCases, id: \.self) {
                $0.text
            }
        } label: {
            Text("Available themes")
        }
    }
}

struct SettingsChosenThemeView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsChosenThemeView(chosenTheme: .constant(nil))
    }
}

#endif
