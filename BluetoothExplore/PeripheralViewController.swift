//
//  PeripheralViewController.swift
//  BluetoothExplore
//
//  Created by TrinaSolar on 2020/1/3.
//  Copyright © 2020 DevQiaoYu. All rights reserved.
//

import UIKit
import CoreBluetooth

class PeripheralViewController: UIViewController {

    @IBOutlet weak var textF: UITextField!
    private var characteristic: CBMutableCharacteristic?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "外围设备"
        
        let service = CBMutableService(type: CBUUID(string: Service_UUID), primary: true)
        characteristic = CBMutableCharacteristic(type: CBUUID(string: Characteristic_UUID), properties: [.read, .write, .notify], value: nil, permissions: [.readable, .writeable])
        service.characteristics = [characteristic!]
        BLEPeripheralManager.shareInstance.stateUpdateBlock = { (state) in
            switch state {
            case .poweredOn:
                BLEPeripheralManager.shareInstance.add(service)
                BLEPeripheralManager.shareInstance.startAdvertising([CBAdvertisementDataServiceUUIDsKey : [CBUUID.init(string: Service_UUID)]])
            default:
                print("")
            }
        }
        
        BLEPeripheralManager.shareInstance.receiveReadBlock = { (request) in
            request.value = self.textF.text?.data(using: .utf8)
            BLEPeripheralManager.shareInstance.respond(to: request, withResult: .success)
        }
        
        BLEPeripheralManager.shareInstance.receiveWriteBlock = { (request) in
            self.textF.text = String.init(data: request.value!, encoding: String.Encoding.utf8)
        }
    }
    
    
    @IBAction func postBtnClick(_ sender: Any) {
        BLEPeripheralManager.shareInstance.updateValue((textF.text ?? "empty data!").data(using: .utf8)!, for: characteristic!, onSubscribedCentrals: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
