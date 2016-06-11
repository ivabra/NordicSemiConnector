//
//  PeripheralsViewController.swift
//  NordicSemiConnect
//
//  Created by Ivan Brazhnikov on 09/06/16.
//  Copyright © 2016 Ivan Brazhnikov. All rights reserved.
//

import UIKit
import CoreBluetooth


private let reuseIdentifier = "cell"
private let peripheralSegueID = "peripheral.show"

private let scanViewHeaderHeight: CGFloat = 120

class PeripheralsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, BluetoothAdapterDelegate {
  
  @objc
  @IBOutlet private weak var tableView:        UITableView!
  
  @IBOutlet weak var scanningView:          ScanningView!
  @IBOutlet weak var scanningContainerView: UIView!
  @IBOutlet weak var scanningStatusLabel:   UILabel!
  
  
  @IBOutlet weak var bottomLayoutGuideConstraint: NSLayoutConstraint!
  
  private var peripherals: [CBPeripheral]!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    title = "vc.peripherals.title".localized
    tableView.contentInset.top += scanViewHeaderHeight
    invalidateScanningStatusText()
    
    let adapter = BluetoothAdapter.sharedAdapter()
    BluetoothAdapter.sharedAdapter().registerDelegate(self)
    reloadData()
    startDiscovering()
    switch adapter.state {
    case .PoweredOn:
      NSTimer.scheduledTimerWithTimeInterval(2.0, target: self, selector: #selector(checkFirstScanResult(_:)), userInfo: nil, repeats: true)
    default:
      moveToTableView()
    }
    
  }
 
  
  
  @objc private func checkFirstScanResult(timer: NSTimer) {
    
    guard peripherals?.count > 0 || BluetoothAdapter.sharedAdapter().state != .PoweredOn else {
      return
    }
    
    timer.invalidate()
    moveToTableView()
    
  }
  

  @objc
  @IBAction private func toggleDiscovering() {
    let adapter = BluetoothAdapter.sharedAdapter()
    if adapter.isScanning {
      stopDiscovering()
    } else {
      startDiscovering()
    }
  }
  
  
  
  private func startDiscovering() {
    let adapter =  BluetoothAdapter.sharedAdapter()
    switch adapter.state {
    case .PoweredOn:
      adapter.startScanning()
    case .PoweredOff:
      showMessage("vc.peripherals.message.enable_bluetooth".localized)
    case .Unauthorized:
      showMessage("vc.peripherals.message.not_authorized".localized)
    case .Unsupported:
      showMessage("vc.peripherals.message.not_supported_bluetooth_le".localized)
    default:
      break
    }
  }
  
  private func stopDiscovering() {
    BluetoothAdapter.sharedAdapter().stopScanning()
  }
  
  private func reloadData() {
    peripherals = Array(BluetoothAdapter.sharedAdapter().discoveredPeripherals)
    tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
  }
  
  
  
  
  // MARK: UITableViewDataSource
  
  func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
    let p = peripherals[indexPath.item]
    cell.textLabel?.text = p.name ?? "Unnamed"
    cell.detailTextLabel?.text = p.identifier.UUIDString
    return cell
  }
  
  
  
  func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return peripherals != nil ? 1 : 0
  }
  
  
  
  func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return peripherals.count
  }
  

  
  
  
  // MARK: BluetoothAdapterDelegate
  
  func bluetoothAdapterDidChangeScanningState(adapter: BluetoothAdapter) {
    invalidateScanningStatusText()
    
    let show = adapter.isScanning
    
    if show {
      scanningView.start()
    }
    
    UIView.animateWithDuration(0.5, animations: { [unowned self] in
        self.scanningView.alpha = show ? 1 : 0
      }, completion: {[weak self] complete in
        if complete {
          if !show {
            self?.scanningView.stop()
          }
        }
    })
  }
  
  func bluetoothAdapter(adapter: BluetoothAdapter, didChangeDiscoveredPeripherals new: CBPeripheral?) {
    if let new = new {
      tableView.beginUpdates()
      tableView.insertRowsAtIndexPaths([NSIndexPath(forItem: peripherals.count, inSection: 0)], withRowAnimation: .Automatic)
      peripherals.append(new)
      tableView.endUpdates()
    } else {
      reloadData()
    }
  }
  
  
  
  
  
  // MARK: UI
  
  
  private func showMessage(message: String) {
    let alert = UIAlertController.init(title: nil, message: message, preferredStyle: .Alert)
    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
    presentViewController(alert, animated: true, completion: nil)
  }
  
  private func invalidateScanningStatusText() {
    scanningStatusLabel.text = (BluetoothAdapter.sharedAdapter().isScanning ? "vc.peripherals.search" : "vc.peripherals.stopped").localized
  }

  
  private func moveToTableView() {
    bottomLayoutGuideConstraint.active = false
    
    scanningContainerView.addConstraint(NSLayoutConstraint.init(item: scanningContainerView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 1.0, constant: 120))
    
    UIView.animateWithDuration(0.5) { [unowned self] in
      self.view.layoutIfNeeded()
    }
    scanningContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(toggleDiscovering)))
    
  }
  
  
  
  
  
  
  // MARK: Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == peripheralSegueID {
      let dest = segue.destinationViewController as! PeripheralControlViewController
      let p = peripherals[tableView.indexPathForCell(sender as! UITableViewCell)!.item]
      dest.peripheral = p
    }
  }
 
 
  
}

class PeripheralTableViewCell: UITableViewCell {
  @IBOutlet weak var nameLabel: UILabel!
  @IBOutlet weak var uuidLabel: UILabel!
  
  override var textLabel: UILabel? {
    return nameLabel
  }
  
  override var detailTextLabel: UILabel? {
    return uuidLabel
  }
  
  
}