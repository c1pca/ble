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
    var peripherials = [CBPeripheral]()
    @IBOutlet weak var availableDevices: NSTableView!
    @IBOutlet weak var connectButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        availableDevices.delegate = self
        availableDevices.dataSource = self
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    @IBAction func buttonTapped(_: AnyObject){
        if let peripherial = availableDevices.selectedRow == -1 ? peripherials.first : peripherials[availableDevices.selectedRow] {
            centralManager.connect(peripherial, options: [:])
        }
    }
}

extension ViewController: NSTableViewDelegate, NSTableViewDataSource {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        
        return peripherials.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let item = peripherials[row]
        
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "PeripherialCellID"), owner: nil) as? NSTableCellView {
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
        if peripherials.firstIndex(of: peripheral) == nil {
            peripherials.append(peripheral)
            availableDevices.reloadData()
        }
    }
}

extension ViewController: CBPeripheralDelegate{
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?){
        guard error != nil else {
            for service in peripheral.services!{
                peripheral.discoverCharacteristics(nil, for: service)
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
    
    func writeValueForPeripheral(peripheral: CBPeripheral, writeCharactist: CBCharacteristic, value: NSData?) {
        if writeCharactist.properties == .writeWithoutResponse {
            peripheral.writeValue(value! as Data, for: writeCharactist, type: .withoutResponse)
        } else {
            peripheral.writeValue(value! as Data, for: writeCharactist, type: .withResponse)
        }
        
        self.centralManager.cancelPeripheralConnection(peripheral)
    }
}
