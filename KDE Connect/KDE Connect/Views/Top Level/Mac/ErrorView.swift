//
//  ErrorView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2023/08/31.
//

import SwiftUI

struct ErrorView: View {
    let reason: String
    
    init(_ reason: String) {
        self.reason = reason
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Error Occured").font(.largeTitle)
            Spacer()
            Text("Reason: " + self.reason)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.pink)
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView("Preview")
    }
}
