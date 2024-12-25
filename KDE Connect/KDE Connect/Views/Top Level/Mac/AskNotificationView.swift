//
//  AskNotificationView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/05/12.
//

import SwiftUI

struct AskNotificationView: View {
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text("Please grant notification permission in order to run KDE Connect.")
                    .foregroundColor(.secondary)
                    .padding(.all)
                Spacer()
            }
            Spacer()
        }
    }
}

struct AskNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        AskNotificationView()
    }
}
