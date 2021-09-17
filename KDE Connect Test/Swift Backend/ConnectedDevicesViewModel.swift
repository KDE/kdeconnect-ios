//
//  ConnectedDevicesViewModel.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-09.
//

import SwiftUI
import UIKit

@objc class ConnectedDevicesViewModel : NSObject {
    var devicesView: DevicesView? = nil
    var currDeviceDetailsView: DevicesDetailView? = nil
    
    var connectedDevices: [String : String] = [:]
    var visibleDevices: [String : String] = [:]
    var savedDevices: [String : String] = [:]
    
    var lastLocalClipboardUpdateTimestamp: Int = 0
        
    @objc func onPairRequest(_ deviceId: String!) -> Void {
        devicesView!.onPairRequestInsideView(deviceId)
    }
    
    @objc func onPairTimeout(_ deviceId: String!) -> Void{
        devicesView!.onPairTimeoutInsideView(deviceId)
    }
    
    @objc func onPairSuccess(_ deviceId: String!) -> Void {
        devicesView!.onPairSuccessInsideView(deviceId)
    }
    
    @objc func onPairRejected(_ deviceId: String!) -> Void {
        devicesView!.onPairRejectedInsideView(deviceId)
    }
    
    // Recalculate AND rerender the lists
    @objc func onDeviceListRefreshed() -> Void {
        let devicesListsMap = backgroundService.getDevicesLists() //[String : [String : Device]]
        connectedDevices = devicesListsMap?["connected"] as! [String : String]
        visibleDevices = devicesListsMap?["visible"] as! [String : String]
        savedDevices = devicesListsMap?["remembered"] as! [String : String]
        devicesView!.onDeviceListRefreshedInsideView(vm: self)
    }
    
    // Refresh Discovery, Recalculate AND rerender the lists
    @objc func refreshDiscoveryAndListInsideView() -> Void {
        devicesView!.refreshDiscoveryAndList()
    }
    
    @objc func reRenderDeviceView() -> Void {
        devicesView!.viewUpdate.toggle()
    }
    
    @objc func reRenderCurrDeviceDetailsView(deviceId: String) -> Void {
        if (currDeviceDetailsView != nil && deviceId == currDeviceDetailsView!.detailsDeviceId) {
            withAnimation {
                connectedDevicesViewModel.currDeviceDetailsView!.viewUpdate.toggle()
            }
        }
    }
    
    @objc func unpair(fromBackgroundServiceInstance deviceId: String) -> Void {
        backgroundService.unpairDevice(deviceId)
    }
    
    @objc static func staticUnpairFromBackgroundService(deviceId: String) -> Void {
        backgroundService.unpairDevice(deviceId)
    }
    
    @objc func currDeviceDetailsViewDisconnected(fromRemote deviceId: String!) -> Void {
        //backgroundService.unpairDevice(deviceId)
        if (currDeviceDetailsView != nil && deviceId == currDeviceDetailsView!.detailsDeviceId) {
            currDeviceDetailsView!.isStilConnected = false
            //onDeviceListRefreshed() // This automatically goes back to DeviceView after unpair is complete
        } //else if (currDeviceDetailsView == nil && devicesView!.currPairingDeviceId != nil) {
            //onDeviceListRefreshed()
        //}
        // MARK: Is this still needed since DeviceView() will refresh it anyways?
        //onDeviceListRefreshed()
        devicesView!.refreshDiscoveryAndList()
    }
    
    @objc func removeDeviceFromArrays(deviceId: String) -> Void {
        //backgroundService._devices.removeObject(forKey: deviceId)
        backgroundService._settings.removeObject(forKey: deviceId)
        UserDefaults.standard.setValue(backgroundService._settings, forKey: "savedDevices")
    }
    
    @objc static func isDeviceCurrentlyPairedAndConnected(_ deviceId: String) -> Bool {
        let doesExistInDevices: Bool = (backgroundService._devices[deviceId] != nil)
        if doesExistInDevices {
            let device: Device = (backgroundService._devices[deviceId] as! Device)
            return (device.isPaired() && device.isReachable())
        } else {
            return false
        }
    }
    
    @objc func showPingAlert() -> Void {
        devicesView!.showPingAlertInsideView()
    }
    
    @objc func showFindMyPhoneAlert() -> Void {
        devicesView!.showFindMyPhoneAlertInsideView()
    }
    
    @objc func showFileReceivedAlert() -> Void {
        devicesView!.showFileReceivedAlertInsideView()
    }
    
    @objc static func getDirectIPList() -> [String] {
        return selfDeviceData.directIPs
    }
}
