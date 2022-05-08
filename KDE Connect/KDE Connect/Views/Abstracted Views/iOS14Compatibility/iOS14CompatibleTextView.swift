//
//  iOS14CompatibleTextView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022-01-20.
//

import UIKit
import SwiftUI

@available(iOS, deprecated: 15, message:
        """
        iOS14CompatibleTextView should only be used for backwards compatibility with iOS 14.
        iOS 15 should follow the new convention of using Text() supporting Markdown attributes.
        """
)
struct iOS14CompatibleTextView: UIViewRepresentable {
    let attributedString: NSAttributedString

    init(_ attributedString: NSAttributedString) {
        self.attributedString = attributedString
    }

    func makeUIView(context: Context) -> some UIView {
        let contributorView = UITextView()
        contributorView.attributedText = attributedString
        contributorView.isEditable = false
        contributorView.isSelectable = true
        contributorView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        contributorView.textContainerInset = .zero
        contributorView.textContainer.lineFragmentPadding = 0
        contributorView.isScrollEnabled = false
        contributorView.layoutManager.usesFontLeading = false
        return contributorView
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

struct iOS14CompatibleTextView_Previews: PreviewProvider {
    static var previews: some View {
        iOS14CompatibleTextView(NSAttributedString(string: "Preview"))
    }
}
