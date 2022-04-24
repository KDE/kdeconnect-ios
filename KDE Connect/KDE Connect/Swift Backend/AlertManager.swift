//
//  AlertManager.swift
//  KDE Connect
//
//  Created by Stefe on 28/02/2022.
//

import Foundation
import SwiftUI
import Combine

struct AlertContent {
    let title: LocalizedStringKey
    @ViewBuilder let content: () -> Text?
    @AlertActionBuilder let buttons: () -> AlertActionBuilder.Buttons
}

/**
 Manages alerts in-app.
 
 
 You should use it instead of  `.alert()`, whenever you can,
 as the default implementation doesn't work with multiple alerts at once.
 Because this app uses alerts that come from background service,
 we have to manage displaying alerts one after another ourselves.
 
 An instance of AlertManager can be passed to a view as an @EnvironmentObject.
 (See MainTabView.swift)
 
 To add an alert use ``queueAlert(prioritize:title:content:buttons:)``.
 */
class AlertManager: ObservableObject {
    var queue: [AlertContent] = []
    
    @Published var alertPresent: Bool = false
    
    @Published var currentAlert: AlertContent = AlertContent(
        title: "",
        content: { Text("") },
        buttons: {}
    )
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.$alertPresent
            .receive(on: DispatchQueue.main)
            .sink { [self] (alertPresent: Bool) in
                if alertPresent == false && self.queue.count != 0{
                    currentAlert = queue.removeFirst()
                    self.alertPresent = true
                }
            }
            .store(in: &cancellables)
    }
    
    /**
     Adds a new alert to the queue and displays it if there isn't one currently on the screen.
     
     - Parameters:
     - prioritize: If true, adds the new alert to the begging of the queue.
     Should be used when an alert is shown as a direct result of user interaction.
     - title: Title of the alert.
     - content: Content (message) of the alert.
     - buttons: Buttons for the alert.
     */
    func queueAlert(
        prioritize: Bool = false,
        title: LocalizedStringKey,
        @ViewBuilder content: @escaping () -> Text?,
        @AlertActionBuilder buttons: @escaping () -> AlertActionBuilder.Buttons
    ) {
        if prioritize {
            queue.insert(AlertContent(title: title, content: content, buttons: buttons), at: 0)
        } else {
            queue.append(AlertContent(title: title, content: content, buttons: buttons))
        }
        if !alertPresent {
            currentAlert = queue.removeFirst()
            alertPresent = true
        }
    }
}
