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

class PeripheralControlViewController: UIViewController, CBPeripheralDelegate, BluetoothAdapterDelegate {
  
  // MARK: - Variables
  
  // MARK: KVO
  private var keyValueContextVar =  0
  
  
  // MARK: IBOutlets
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var toggleButton: UIBarButtonItem!
  @IBOutlet weak var beginUpdatingButton: UIBarButtonItem!
  
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
    printInTextView(peripheral.name ?? "Unnamed")
    BluetoothAdapter.sharedAdapter().registerDelegate(self)
    
    updateToggleConnectionButtonState()
    updateListenCharacteristicButtonState()
    
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setToolbarHidden(false, animated: animated)
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
    textView.text = peripheral.name
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
  
  func printInTextView(text: String) {
    dispatch_async(dispatch_get_main_queue()) {[weak self] in
      self?.textView.text! += "-> \(text)\n"
    }
  }
  
  func updateListenCharacteristicButtonState() {
    beginUpdatingButton.title = updating ? "Stop" : "Start"
    beginUpdatingButton.enabled = peripheral.state == .Connected
  }
  
  func updateToggleConnectionButtonState() {
    switch peripheral.state {
    case .Connected:
      toggleButton.title = "Disconnect"
      toggleButton.enabled = true
    case .Disconnected:
      toggleButton.title = "Connect"
      toggleButton.enabled = true
    case .Connecting:
      toggleButton.title = "Connecting"
      toggleButton.enabled = false
    case .Disconnecting:
      toggleButton.title = "Disconnecting"
      toggleButton.enabled = false
    }
  }
  
  
  // MARK: BluetoothAdapterDelegate
  
  func bluetoothAdapter(adapter: BluetoothAdapter, didConnectPeripheral peripheral: CBPeripheral) {
    guard peripheral == self.peripheral else { return }
    printInTextView("Connected")
  }
  
  func bluetoothAdapter(adapter: BluetoothAdapter, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
    guard peripheral == self.peripheral else { return }
    service = nil
    characteristics = nil
    printInTextView("Disconnected")
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
    
    if let error = error {
      printInTextView("\(error.localizedDescription)")
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
    
    if let error = error {
      printInTextView("\(error.localizedDescription)")
    }
  }
  
  
  
  func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
    
    if let error = error {
      printInTextView(error.localizedDescription)
      return
    }
    
    guard let data = characteristic.value else {
      return
    }
    
    let toprint: Any
    switch data.length {
    case sizeof(Double):
      var doubleValue = 0.0
      data.getBytes(&doubleValue, length: sizeof(Double))
      toprint = doubleValue
    case sizeof(Float):
      var floatValue: Float = 0.0
      data.getBytes(&floatValue, length: sizeof(Double))
      toprint = floatValue
    default:
      toprint = data.description
      break
    }
    
    dispatch_async(dispatch_get_main_queue()) { [weak self] in
      self?.printInTextView(  "\(toprint)")
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