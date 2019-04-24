//
//  ViewController.swift
//  ble_data
//
//  Created by Yurii Tkachyshyn on 4/19/19.
//  Copyright © 2019 Yurii Tkachyshyn. All rights reserved.
//

import Cocoa
import CoreBluetooth

class ViewController: NSViewController {
    
    var centralManager : CBCentralManager!
    var peripheral: CBPeripheral!
    var charactaristic: CBCharacteristic!
    var error: NSError!
    
    let dataServiceUuid = CBUUID(string: "FFE0")
    let dataCharactersisticUuid = CBUUID(string: "FFE1")
    var peripherals = [CBPeripheral]()
    @IBOutlet weak var availableDevices: NSTableView!
    @IBOutlet weak var connectButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        availableDevices.delegate = self
        availableDevices.dataSource = self
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    @IBAction func buttonTapped(_: AnyObject){
        if let peripheral = availableDevices.selectedRow == -1 ? peripherals.first : peripherals[availableDevices.selectedRow] {
            peripheral.delegate = self
            centralManager.connect(peripheral, options: [:])
            centralManager.stopScan()
        }
    }
}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return peripherals.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = peripherals[row]
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PeripheralCellID"), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = item.identifier.uuidString
            return cell
        }
        return nil
    }
}

extension ViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            print("Turn bluetooth on")
            
        } else if central.state == .poweredOn {
            let _options = [String : Any]()
            centralManager.scanForPeripherals(withServices: [dataServiceUuid], options: _options)
        } else if central.state == .unsupported {
            print("unsupported")
        }
    }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripherals.firstIndex(of: peripheral) == nil {
            peripherals.append(peripheral)
            availableDevices.reloadData()
        }
    }
}

extension ViewController: CBPeripheralDelegate{
    public func didDiscoverCharacteristicsFor(characteristic: CBCharacteristic) {

    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error erroe: Error?){
        if error != nil {
            print(self, "didDiscoverCharacteristicsFor", "\(error.debugDescription)")
            
            return
        }
        guard error != nil else{
            for _characteristic in service.characteristics! {
                self.peripheral?.setNotifyValue(true, for: _characteristic)
                    if _characteristic.properties == .write ||
                        _characteristic.properties == .writeWithoutResponse{
                        self.peripheral?.setNotifyValue(false, for: _characteristic)
                        self.charactaristic = _characteristic
                }
            }
            return
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        guard error != nil else {
            for service in peripheral.services!{
                print("Searching for services in peripheral:", peripheral)
                service.peripheral.discoverCharacteristics([dataCharactersisticUuid], for: service)
                service.peripheral.discoverCharacteristics(nil, for: service)
            }
            return
        }
    }
}

extension ViewController{
    func scanForPeripherals(central: CBCentralManager, peripheral: CBPeripheral!, error: NSError!){
        var _options = [String : Any]()
        _options[CBCentralManagerScanOptionAllowDuplicatesKey] = false
        print("Scranning for all services");
        centralManager.scanForPeripherals(withServices: [dataServiceUuid], options: _options)
        print ("scanning...")
        print (centralManager.scanForPeripherals(withServices: [dataServiceUuid], options: _options))

    }
    
    func writeValueForPeripheral(peripheral: CBPeripheral, characteristic: CBCharacteristic, value: NSData?) {
        if characteristic.properties == .writeWithoutResponse {
            peripheral.writeValue(value! as Data, for: charactaristic, type: .withoutResponse)
        } else {
            peripheral.writeValue(value! as Data, for: charactaristic, type: .withResponse)
        }
        
        self.centralManager.cancelPeripheralConnection(peripheral)
    }
}
