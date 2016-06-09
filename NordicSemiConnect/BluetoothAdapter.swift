//
//  BluetoothAdapter.swift
//  NordicSemiConnect
//
//  Created by Ivan Brazhnikov on 08/06/16.
//  Copyright © 2016 Ivan Brazhnikov. All rights reserved.
//

import Foundation
import CoreBluetooth

private let bt_queue = dispatch_queue_create("com.dantelab.NordicSemiConnect", DISPATCH_QUEUE_SERIAL)


@objc protocol BluetoothAdapterDelegate {
  optional func bluetoothAdapter(adapter: BluetoothAdapter, didChangeDiscoveredPeripherals new: CBPeripheral?)
  optional func bluetoothAdapter(adapter: BluetoothAdapter, didConnectPeripheral peripheral: CBPeripheral)
  optional func bluetoothAdapter(adapter: BluetoothAdapter, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?)
  optional func bluetoothAdapter(adapter: BluetoothAdapter, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?)
  optional func bluetoothAdapterDidChangeState(adapter: BluetoothAdapter)
  optional func bluetoothAdapterDidChangeScanningState(adapter: BluetoothAdapter)
}


class WeakWrapper<T: AnyObject> {
  
  weak var value: T!
  
  init(_ value: T) {
    self.value = value
  }
}



class BluetoothAdapter: NSObject, CBCentralManagerDelegate {
  
  private var keyValueContextVar = 0
  
  private var manager: CBCentralManager!
  private var delegates = [Int : WeakWrapper<BluetoothAdapterDelegate>]()
  private(set) var discoveredPeripherals = Set<CBPeripheral>()
  
  
  init(identifier: String) {
    super.init()
    manager = CBCentralManager(delegate: self, queue: bt_queue, options: [CBCentralManagerOptionRestoreIdentifierKey : identifier])
    manager.addObserver(self, forKeyPath: "isScanning", options: [.New], context: &keyValueContextVar)
  }
  
  deinit {
    manager.removeObserver(self, forKeyPath: "isScanning", context: &keyValueContextVar)
  }
  
  
  
  func registerDelegate(delegate: BluetoothAdapterDelegate) {
    let id = ObjectIdentifier(delegate).hashValue
    delegates[id] = WeakWrapper(delegate)
  }
  
  func unregisterDelegate(delegate: BluetoothAdapterDelegate) {
    let id = ObjectIdentifier(delegate).hashValue
    delegates.removeValueForKey(id)
  }
  
  
  func startScanning(allowDublicate: Bool = false) {
    
    discoveredPeripherals.removeAll()
    
    callDelegates { (adapter, delegate) in
      delegate.bluetoothAdapter?(adapter, didChangeDiscoveredPeripherals: nil)
    }
    
    manager.scanForPeripheralsWithServices(nil, options: [CBCentralManagerScanOptionAllowDuplicatesKey : allowDublicate])
  }

  
  func stopScanning() {
    manager.stopScan()
  }
  
  var isScanning: Bool {
    return manager.isScanning
  }
  
  var state: CBCentralManagerState {
    return manager.state
  }
  
  
  

  func connectPeripheral(peripheral: CBPeripheral) {
    manager.connectPeripheral(peripheral, options: [CBConnectPeripheralOptionNotifyOnConnectionKey : true, CBConnectPeripheralOptionNotifyOnNotificationKey : true, CBConnectPeripheralOptionNotifyOnDisconnectionKey : true])
  }
  
  func disconnectPeripheral(peripheral: CBPeripheral) {
    manager.cancelPeripheralConnection(peripheral)
  }
  
  

  private func callDelegates(block: (adapter: BluetoothAdapter,  delegate: BluetoothAdapterDelegate) -> Void) {
    
    guard !delegates.isEmpty else { return }
    
    dispatch_async(dispatch_get_main_queue()) {[weak self] in
      guard let s = self where !s.delegates.isEmpty else { return }
      for d in s.delegates.values {
        assert(d.value != nil, "You should unregister delegate before it deinitialization")
        block(adapter: s, delegate: d.value )
      }
    }
  }
  
  

  
  //MARK: CBCentralManagerDelegate
  
  
  func centralManager(central: CBCentralManager, willRestoreState dict: [String : AnyObject]) {
    if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
      self.discoveredPeripherals = Set(peripherals)
      callDelegates { (adapter, delegate) in
        delegate.bluetoothAdapter?(adapter, didChangeDiscoveredPeripherals: nil)
      }
    }
  }
  
  
  func centralManagerDidUpdateState(central: CBCentralManager) {
    callDelegates { (adapter, delegate) in
      delegate.bluetoothAdapterDidChangeState?(adapter)
    }
  }
  
  
  func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
    
    discoveredPeripherals.insert(peripheral)
    
    callDelegates { (adapter, delegate) in
      delegate.bluetoothAdapter?(adapter, didChangeDiscoveredPeripherals: peripheral)
    }
  }
  
  
  func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    callDelegates { (adapter, delegate) in
      delegate.bluetoothAdapter?(adapter, didDisconnectPeripheral: peripheral, error: error)
    }
  }
  
  
  func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
    callDelegates { (adapter, delegate) in
      delegate.bluetoothAdapter?(adapter, didConnectPeripheral: peripheral)
    }
  }
  
  
  func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    callDelegates { (adapter, delegate) in
      delegate.bluetoothAdapter?(adapter, didFailToConnectPeripheral: peripheral, error: error)
    }
  }
  
  
  
  // MARK: KVO
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    
    guard context == &keyValueContextVar else {
      super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
      return
    }
    
    if object === manager {
      if keyPath == "isScanning" {
        callDelegates({ (adapter, delegate) in
          delegate.bluetoothAdapterDidChangeScanningState?(adapter)
        })
      }
    }
  }
  
}

// MARK: Singletone
extension BluetoothAdapter {
  
  private static var instance: BluetoothAdapter!
  
  static func initializeWithRestoreIdentifier(identifier: String) {
    instance = BluetoothAdapter(identifier:identifier)
  }
  
  static func sharedAdapter() -> BluetoothAdapter {
    assert(instance != nil, "You should call initializeWithRestoreIdentifier(_:) before getting shared adapter")
    return instance
  }
}


extension CBCentralManagerState: CustomStringConvertible {
  public var description: String {
    switch self {
    case .PoweredOff:   return "Powered Off"
    case .PoweredOn:    return "Powered On"
    case .Resetting:    return "Resetting"
    case .Unauthorized: return "Unathorized"
    case .Unknown:      return "Unknown"
    case .Unsupported:  return "Unsupported"
   }
  }
}

 