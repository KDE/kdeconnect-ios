/*
 * SPDX-FileCopyrightText: 2021 Lucas Wang <lucas.wang@tuta.io>
 *
 * SPDX-License-Identifier: GPL-2.0-only OR GPL-3.0-only OR LicenseRef-KDE-Accepted-GPL
 */

import SwiftUI

// A wrapper view for the iOS 14 Alert implementation.
// Since .alert modifiers cannot be chained in iOS 14, an invisible Textbox
// hidden from accessibility features is need for each alert
@available(iOS, deprecated: 15, message:
        """
        iOS14CompatibilityAlert should only be used for backwards
        compatibility with iOS 14. iOS 15 should follow the new convention
        of using the .alert modifier without an Alert() struct instead.
        """
)
struct iOS14CompatibilityAlert: View {
    let description: String
    @Binding var isPresented: Bool
    let alert: Alert
    
    var body: some View {
        Text(description)
            .frame(width: 0, height: 0)
            .opacity(0)
            .accessibilityHidden(true)
            .alert(isPresented: $isPresented) {
                alert
            }
    }
}

//struct iOS14CompatibilityAlert_Previews: PreviewProvider {
//    static var previews: some View {
//        iOS14CompatibilityAlert()
//    }
//}
