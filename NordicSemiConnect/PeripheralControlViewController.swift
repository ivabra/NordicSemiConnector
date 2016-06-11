//
//  PeripheralControlViewController.swift
//  NordicSemiConnect
//
//  Created by Ivan Brazhnikov on 09/06/16.
//  Copyright © 2016 Ivan Brazhnikov. All rights reserved.
//

import UIKit
import CoreBluetooth

private let cellIdentifier = "cell"
private let numberFormatter = { () -> NSNumberFormatter in
  let f = NSNumberFormatter()
  f.numberStyle  = NSNumberFormatterStyle.DecimalStyle
  f.decimalSeparator = "."
  return f
}()

class PeripheralControlViewController: UIViewController, CBPeripheralDelegate, BluetoothAdapterDelegate {
  
  // MARK: - Variables
  
  // MARK: KVO
  private var keyValueContextVar =  0
  
  
  // MARK: IBOutlets
  @IBOutlet weak var toggleButton: UIButton!
  @IBOutlet weak var beginUpdatingButton: UIButton!
  @IBOutlet weak var gravityView: GravityView!
  @IBOutlet weak var gravityLabel: UILabel!
  
  // MARK: Core Bluetooth
  var peripheral: CBPeripheral!
  var service: CBService?
  var characteristics: [CBCharacteristic]?
  
  var updating = false {
    didSet {
      updateListenCharacteristicButtonState()
    }
  }
  
  // MARK: - Methods
  // MARK: UIViewController
  
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    peripheral.delegate = self
    peripheral.addObserver(self, forKeyPath: "state", options: [.New, .Initial], context: &keyValueContextVar)
    title = peripheral.name
    BluetoothAdapter.sharedAdapter().registerDelegate(self)
    
    updateToggleConnectionButtonState()
    updateListenCharacteristicButtonState()
    
  } 
  
  deinit {
    peripheral?.delegate = nil
    BluetoothAdapter.sharedAdapter().unregisterDelegate(self)
    peripheral.removeObserver(self, forKeyPath: "state", context: &keyValueContextVar)
    disconnect()
  }
  
  
  // MARK: Interface actions
  
  @objc
  @IBAction private func toggleConnection(sender: AnyObject) {
    if peripheral.state == .Disconnected {
      connect()
    } else {
      disconnect()
    }
  }
  
  @objc
  @IBAction private func beginUpdating(sender: AnyObject) {
    if service == nil {
      discoverServices()
    } else if characteristics == nil {
      discoverCharacteristics()
    } else {
      setNotify(!updating)
    }
  }
  
  // MARK: Connection logic
  
  private func connect() {
    BluetoothAdapter.sharedAdapter().connectPeripheral(peripheral)
  }
  
  private func disconnect() {
    BluetoothAdapter.sharedAdapter().disconnectPeripheral(peripheral)
    updating = false
  }
  
  
  private func discoverServices() {
    peripheral?.discoverServices([CBUUID.init(string: UARTServiceUUID)])
  }
  
  private func discoverCharacteristics() {
    guard let service = self.service else { return }
    peripheral.discoverCharacteristics([CBUUID(string: UARTRXCharacteristicUUID)], forService: service)
  }
  
  
  private func setNotify(notify: Bool) {
    guard let characteristics = characteristics else { return }
    self.updating = notify
    for ch in characteristics  {
      peripheral.setNotifyValue(notify, forCharacteristic: ch)
    }
  }
  
  
  // MARK: Updating UI
  
  
  func updateListenCharacteristicButtonState() {
    
    beginUpdatingButton.setTitle((updating ? "vc.peripheral.stop" : "vc.peripheral.start").localized, forState: .Normal)
    beginUpdatingButton.setTitleColor(updating ? .redColor() : nil, forState: .Normal)
    beginUpdatingButton.enabled = peripheral.state == .Connected
  }
  
  func updateToggleConnectionButtonState() {
    let title: String
    let enabled: Bool
    switch peripheral.state {
    case .Connected:
      title   = "vc.peripheral.disconnect"
      enabled = true
    case .Disconnected:
      title   = "vc.peripheral.connect"
      enabled = true
    case .Connecting:
      title   = "vc.peripheral.connecting"
      enabled = false
    case .Disconnecting:
      title   = "vc.peripheral.disconnecting"
      enabled = false
    }
    toggleButton.setTitle(title.localized, forState: .Normal)
    toggleButton.enabled = enabled
  }
  
  
  // MARK: BluetoothAdapterDelegate
  
  func bluetoothAdapter(adapter: BluetoothAdapter, didConnectPeripheral peripheral: CBPeripheral) {
    guard peripheral == self.peripheral else { return }
  }
  
  func bluetoothAdapter(adapter: BluetoothAdapter, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    guard peripheral == self.peripheral else { return }
    service = nil
    characteristics = nil
  }
  
  
  
  // MARK: CBPeripheralDelegate
  

  func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
    
    guard let service = peripheral.services?.first else { return }
    
    self.service = service
    
    dispatch_async(dispatch_get_main_queue()) {[weak self] in
      self?.discoverCharacteristics()
    }
  }
  
  
  
  func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
    
    if error != nil {
      return
    }
    
    guard let characteristics = service.characteristics else {
      return
    }
    
    self.characteristics = characteristics
    
    dispatch_async(dispatch_get_main_queue()) {[weak self] in
      self?.setNotify(true)
    }
  }
  
  
  
  
  func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
    
  }
  
  
  
  func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
    
    if error != nil {
      return
    }
    
    guard let data = characteristic.value, result = String(data: data, encoding: NSASCIIStringEncoding) else {
      return
    }
    
    
    let value = numberFormatter.numberFromString(result)?.doubleValue ?? 1.0
    
  
    dispatch_async(dispatch_get_main_queue()) { [weak self] in
      guard let s = self else  { return }
      s.gravityLabel.text = String(format: "%0.2f", value)
      s.gravityView.progress = CGFloat(value) / 2
    }
  }
  
  
  func peripheralDidUpdateState() {
    updateToggleConnectionButtonState()
    updateListenCharacteristicButtonState()
  }
  
  
  
  // MARK: KVO
  
  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    guard context == &keyValueContextVar else {
      super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
      return
    }
    
    if object === peripheral && keyPath == "state" {
      dispatch_async(dispatch_get_main_queue(), {[weak self] in
        self?.peripheralDidUpdateState()
        })
    }
  }
  
}