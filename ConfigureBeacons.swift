//
//  ConfigureBeacons.swift
//  ---
//
//  Created by Usman on 16/04/2020.
//  Copyright © 2020. All rights reserved.
//

import Alamofire
import CoreBluetooth
import CoreLocation
import Foundation


// MARK: - Class: Beacons Configuration & Broadcasting

@available(iOS 13.0, *)
class ConfigureBeacons: NSObject, CBPeripheralManagerDelegate {
    var otherUserIdDetectedArray = [NSNumber]()
    
    // MARK: Properties
    
    var peripheralManager: CBPeripheralManager?
    var region: CLBeaconRegion?
    var major: UInt16 = 0
    var minor: UInt16 = 0
    var beaconConstraints = [CLBeaconIdentityConstraint: [CLBeacon]]()
    var beacons = [CLProximity: [CLBeacon]]()
    var locationManager = CLLocationManager()
    var centralManager: CBCentralManager?
    
    func configure() {
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)
//        startIBeaconBroadCast()
    }
    
    private func startIBeaconBroadCast() {
        configureBeaconRegion()
        setupBeaconsReceiever()
    }
    
    private func configureBeaconRegion() {
        if peripheralManager?.state == .poweredOn {
            peripheralManager?.stopAdvertising()
            
            let bundleURL = Bundle.main.bundleIdentifier!
            
            // Defines the beacon identity characteristics the device broadcasts.
        
            minor  = 50
            major = 100
           
            if let uuid = UUID(uuidString: "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0") {
                let constraint = CLBeaconIdentityConstraint(uuid: uuid, major: userId, minor: minor)
                region = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: bundleURL)
            }else{
                // handler ....
            }
            
            let peripheralData = region?.peripheralData(withMeasuredPower: nil) as? [String: Any]
            
            // Start broadcasting the beacon identity characteristics.
            peripheralManager?.startAdvertising(peripheralData)
            
        } else {
            // handler ...
        }
    }
    
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .poweredOn:
            startIBeaconBroadCast()
        case .poweredOff:
            // handler ...
            break
        case .resetting:
            startIBeaconBroadCast()
        default:
            // handler ...
            break
        }
    }
    
    func stopBeacons() {
        stopBroadcasting()
        stopBeaconsReceiver()
    }
    
    fileprivate func stopBroadcasting() {
        peripheralManager?.stopAdvertising()
    }
}

// MARK: - Extension: Ranging Beacons, Receiving and Observing region update.

@available(iOS 13.0, *)
extension ConfigureBeacons: CLLocationManagerDelegate {
   
    fileprivate func setupBeaconsReceiever() {
        locationManager.delegate = self
        addBeaconsRegion()
    }
    
    fileprivate func stopBeaconsReceiver() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        // Stop ranging when the view disappears.
        for constraint in beaconConstraints.keys {
            locationManager.stopRangingBeacons(satisfying: constraint)
        }
    }
    
    fileprivate func addBeaconsRegion() {
        if let uuid = beaconUUID {
            locationManager.requestWhenInUseAuthorization()
            
            // Create a new constraint and add it to the dictionary.
            let constraint = CLBeaconIdentityConstraint(uuid: uuid)
            beaconConstraints[constraint] = []
            
            /*
             By monitoring for the beacon before ranging, the app is more
             energy efficient if the beacon is not immediately observable.
             */
            let beaconRegion = CLBeaconRegion(beaconIdentityConstraint: constraint, identifier: uuid.uuidString)
            locationManager.startMonitoring(for: beaconRegion)
        }
    }
    
    // MARK: - Location Manager Delegate
    
    /// - Tag: didDetermineState
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        let beaconRegion = region as? CLBeaconRegion
        if state == .inside {
            // Start ranging when inside a region.
            manager.startRangingBeacons(satisfying: beaconRegion!.beaconIdentityConstraint)
        } else {
            // Stop ranging when not inside a region.
            manager.stopRangingBeacons(satisfying: beaconRegion!.beaconIdentityConstraint)
        }
    }
    
    // MARK: - Tag: didRange
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint: CLBeaconIdentityConstraint) {
        /*
         Beacons are categorized by proximity. A beacon can satisfy
         multiple constraints and can be displayed multiple times.
         */
        beaconConstraints[beaconConstraint] = beacons
        
        self.beacons.removeAll()
        
        var allBeacons = [CLBeacon]()
        
        for regionResult in beaconConstraints.values {
            allBeacons.append(contentsOf: regionResult)
        }
        
        for range in [CLProximity.unknown, .immediate, .near, .far] {
            let proximityBeacons = allBeacons.filter { $0.proximity == range }
            if !proximityBeacons.isEmpty {
                self.beacons[range] = proximityBeacons
            }
        }
        
        // deal with received beacons here .....
        
    }
}
