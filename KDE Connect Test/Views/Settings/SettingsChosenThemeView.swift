//
//  SettingsChosenThemeView.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-06-19.
//

import SwiftUI

struct SettingsChosenThemeView: View {
    @Binding var chosenTheme: String
    let themes: [String] = ["System Default", "Light", "Dark"]
    
    var body: some View {
        VStack {
            Picker("Avaliable themes", selection: $chosenTheme) {
                ForEach(themes, id: \.self) {
                    Text($0)
                }
            }
        }
        .navigationTitle("Choose App Theme")
    }
}

struct SettingsChosenThemeView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsChosenThemeView(chosenTheme: .constant("System Default"))
    }
}
