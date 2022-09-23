//
//  SettingsBackgroundView.swift
//  KDE Connect
//
//  Created by Ruixuan Tu on 2022/09/23.
//

import SwiftUI
import CoreLocation.CLLocationManager

class LocationViewModel: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var typeStr: String = "Unknown"
    @Published var typeIconName: String = "questionmark.circle.fill"
    @Published var typeIconColor: Color = .yellow
    
    private let locationManager: CLLocationManager
    
    override init() {
        locationManager = CLLocationManager()
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        self.updateStates(authorizationStatus)
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.showsBackgroundLocationIndicator = true
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.updateStates(manager.authorizationStatus)
    }
    
    private func updateStates(_ status: CLAuthorizationStatus) {
        self.authorizationStatus = authorizationStatus
        typeStr = self.getTypeStr(status)
        typeIconName = self.getTypeIconName(status)
        typeIconColor = self.getTypeIconColor(status)
    }
    
    public func requestWhenInUse() {
        return locationManager.requestWhenInUseAuthorization()
    }
    
    public func requestAlways() {
        return locationManager.requestAlwaysAuthorization()
    }
    
    public func start() {
        stop()
        locationManager.startUpdatingLocation()
        locationManager.startMonitoringSignificantLocationChanges()
    }
    
    public func stop() {
        locationManager.stopUpdatingLocation()
        locationManager.stopMonitoringSignificantLocationChanges()
    }
    
    private func getTypeStr(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways:
            return "Always"
        case .authorizedWhenInUse:
            return "When In Use"
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        default:
            return "Unknown"
        }
    }
    
    private func getTypeIconName(_ status: CLAuthorizationStatus) -> String {
        switch status {
        case .authorizedAlways:
            return "checkmark.circle.fill"
        case .authorizedWhenInUse:
            return "circle.righthalf.filled"
        case .notDetermined:
            return "circle.dashed"
        case .denied:
            return "exclamationmark.circle.fill"
        default:
            return "questionmark.circle.fill"
        }
    }
    
    private func getTypeIconColor(_ status: CLAuthorizationStatus) -> Color {
        switch status {
        case .authorizedAlways:
            return .green
        case .denied:
            return .red
        default:
            return .yellow
        }
    }
}

struct SettingsBackgroundView: View {
    @StateObject var locationViewModel = LocationViewModel()
    
    var body: some View {
        List {
            Section {
                Label {
                    Text(locationViewModel.typeStr)
                } icon: {
                    Image(systemName: locationViewModel.typeIconName).foregroundColor(locationViewModel.typeIconColor)
                }
            } header: {
                Text("Current Location Permission")
            }
            Section {
                Button {
                    locationViewModel.requestWhenInUse()
                } label: {
                    Label("When In Use", systemImage: "1.circle")
                        .labelStyle(.accessibilityTitleOnly)
                        .accentColor(.primary)
                }
                Button {
                    locationViewModel.requestAlways()
                } label: {
                    Label("Always", systemImage: "2.circle")
                        .labelStyle(.accessibilityTitleOnly)
                        .accentColor(.primary)
                }
            } header: {
                Text("Grant Location Permission for")
            } footer: {
                VStack {
                    Text("""
                        KDE Connect will be able to run in background if be granted always location access\n\n\
                        To grant always permission, grant When In Use by Button 1 then Always by Button 2, or grant When In Use by Button 2 and change in Settings app
                        """)
                }
            }
            Section {
                Button {
                    locationViewModel.start()
                } label: {
                    Label("Start Location Update", systemImage: "play")
                        .labelStyle(.accessibilityTitleOnly)
                        .accentColor(.primary)
                }
                Button {
                    locationViewModel.stop()
                } label: {
                    Label("Stop Location Update", systemImage: "stop")
                        .labelStyle(.accessibilityTitleOnly)
                        .accentColor(.primary)
                }
            } header: {
                Text("Control")
            } footer: {
                Text("KDE Connect will run in background if location update has been started")
            }
        }.navigationTitle("Background Settings")
    }
}

struct SettingsBackgroundView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsBackgroundView()
    }
}
