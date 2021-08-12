//
//  ConnectedDevicesViewModel.swift
//  KDE Connect Test
//
//  Created by Lucas Wang on 2021-08-09.
//

import Foundation

class ConnectedDevicesViewModel : NSObject, backgroundServiceDelegate {
    var devicesView: DevicesView? = nil
    var currDeviceDetailsView: DevicesDetailView? = nil
    
    var connectedDevices: [String : String] = [:]
    var visibleDevices: [String : String] = [:]
    var savedDevices: [String : String] = [:]
    
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
    
    func currDeviceDetailsViewDisconnected(fromRemote deviceId: String!) -> Void {
        if (currDeviceDetailsView != nil && deviceId == currDeviceDetailsView!.detailsDeviceId) {
            currDeviceDetailsView!.isStilConnected = false
            //onDeviceListRefreshed() // This automatically goes back to DeviceView after unpair is complete
        } //else if (currDeviceDetailsView == nil && devicesView!.currPairingDeviceId != nil) {
            //onDeviceListRefreshed()
        //}
        onDeviceListRefreshed()
    }
}
