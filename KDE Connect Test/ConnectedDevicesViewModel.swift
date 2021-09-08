//
//  ConnectedDevicesViewModel.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-09.
//

import UIKit

@objc class ConnectedDevicesViewModel : NSObject, backgroundServiceDelegate {
    var devicesView: DevicesView? = nil
    var currDeviceDetailsView: DevicesDetailView? = nil
    
    var connectedDevices: [String : String] = [:]
    var visibleDevices: [String : String] = [:]
    var savedDevices: [String : String] = [:]
    
    var lastLocalClipboardUpdateTimestamp: Int = 0
        
    func onPairRequest(_ deviceId: String!) -> Void {
        devicesView!.onPairRequestInsideView(deviceId)
    }
    
    func onPairTimeout(_ deviceId: String!) -> Void{
        devicesView!.onPairTimeoutInsideView(deviceId)
    }
    
    func onPairSuccess(_ deviceId: String!) -> Void {
        devicesView!.onPairSuccessInsideView(deviceId)
    }
    
    func onPairRejected(_ deviceId: String!) -> Void {
        devicesView!.onPairRejectedInsideView(deviceId)
    }
    
    func onDeviceListRefreshed() -> Void {
        let devicesListsMap = backgroundService.getDevicesLists() //[String : [String : Device]]
        connectedDevices = devicesListsMap?["connected"] as! [String : String]
        visibleDevices = devicesListsMap?["visible"] as! [String : String]
        savedDevices = devicesListsMap?["remembered"] as! [String : String]
        devicesView!.onDeviceListRefreshedInsideView(vm: self)
    }
    
    func refreshDiscoveryAndListInsideView() -> Void {
        devicesView!.refreshDiscoveryAndList()
    }
    
    func unpair(fromBackgroundServiceInstance deviceId: String) -> Void {
        backgroundService.unpairDevice(deviceId)
    }
    
    func currDeviceDetailsViewDisconnected(fromRemote deviceId: String!) -> Void {
        //backgroundService.unpairDevice(deviceId)
        if (currDeviceDetailsView != nil && deviceId == currDeviceDetailsView!.detailsDeviceId) {
            currDeviceDetailsView!.isStilConnected = false
            //onDeviceListRefreshed() // This automatically goes back to DeviceView after unpair is complete
        } //else if (currDeviceDetailsView == nil && devicesView!.currPairingDeviceId != nil) {
            //onDeviceListRefreshed()
        //}
        // MARK: Is this still needed since DeviceView() will refresh it anyways?
        //onDeviceListRefreshed()
    }
    
    func showPingAlert() -> Void {
        devicesView!.showPingAlertInsideView()
    }
    
    func showFindMyPhoneAlert() -> Void {
        devicesView!.showFindMyPhoneAlertInsideView()
    }
    
    func showFileReceivedAlert() -> Void {
        devicesView!.showFileReceivedAlertInsideView()
    }
    
    @objc static func getDirectIPList() -> [String] {
        return selfDeviceData.directIPs
    }
}
