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

class PeripheralsViewController: UITableViewController, BluetoothAdapterDelegate {
  
  @IBOutlet weak var startScanningButton:       UIBarButtonItem!
  @IBOutlet weak var stopScanningButton:        UIBarButtonItem!
  @IBOutlet weak var scanActivityIndicatorView: UIActivityIndicatorView!
  
  private var peripherals: [CBPeripheral]!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    BluetoothAdapter.sharedAdapter().registerDelegate(self)
    reloadData()
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setToolbarHidden(true, animated: animated)
  }
  
  
  @objc
  @IBAction private func startDiscovering(sender: AnyObject) {
    BluetoothAdapter.sharedAdapter().startScanning()
  }
  
  @IBAction private func stopDiscovering(sender: AnyObject) {
    BluetoothAdapter.sharedAdapter().stopScanning()
  }
  
  private func reloadData() {
    peripherals = Array(BluetoothAdapter.sharedAdapter().discoveredPeripherals)
    tableView.reloadSections(NSIndexSet(index: 0), withRowAnimation: .Automatic)
  }
  
  
  
  
  // MARK: UITableViewDataSource
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier(reuseIdentifier, forIndexPath: indexPath)
    let p = peripherals[indexPath.item]
    cell.textLabel?.text = p.name ?? "Unnamed"
    cell.detailTextLabel?.text = p.description
    return cell
  }
  
  
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return peripherals.count
  }
  
  
  
  // MARK: BluetoothAdapterDelegate
  
  func bluetoothAdapterDidChangeScanningState(adapter: BluetoothAdapter) {
    startScanningButton.enabled = !adapter.isScanning
    stopScanningButton.enabled = adapter.isScanning
    if adapter.isScanning {
      scanActivityIndicatorView.startAnimating()
    } else {
      scanActivityIndicatorView.stopAnimating()
    }
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
  
  // MARK: Navigation
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == peripheralSegueID { 
      (segue.destinationViewController as? PeripheralControlViewController)?.peripheral = peripherals[tableView.indexPathForCell(sender as! UITableViewCell)!.item]
    }
  }
  
}