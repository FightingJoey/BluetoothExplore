//
//  CharacteristicDetailViewController.swift
//  BluetoothExplore
//
//  Created by TrinaSolar on 2020/1/3.
//  Copyright © 2020 DevQiaoYu. All rights reserved.
//

import UIKit
import CoreBluetooth

class CharacteristicDetailViewController: UIViewController {

    @IBOutlet weak var testF: UITextField!
    var characteristic: CBCharacteristic?
    @IBOutlet weak var notifyBtn: UIButton!
    
    var connectL: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        title = characteristic?.uuid.description
        
        let item = UIBarButtonItem(customView: connectL)
        self.navigationItem.rightBarButtonItem = item
                
        characteristic?.service.peripheral.readValue(characteristic!, { (value) in
            self.testF.text = String.init(data: value, encoding: String.Encoding.utf8)
        })
        characteristic?.service.peripheral.connectBlock = { (state) in
            self.updateConnectState()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateConnectState()
    }
    
    func updateConnectState() {
        switch self.characteristic!.service.peripheral.state {
        case .disconnected:
            connectL.text = "未连接"
            connectL.textColor = .gray
        case .connected:
            connectL.text = "已连接"
            connectL.textColor = .green
        case .connecting:
            connectL.text = "连接中"
            connectL.textColor = .orange
        default:
            connectL.text = ""
        }
    }

    @IBAction func getBtnClick(_ sender: Any) {
        characteristic?.service.peripheral.readValue(for: characteristic!)
    }
    
    @IBAction func postBtnClick(_ sender: Any) {
        if let data = (self.testF.text ?? "empty input")!.data(using: String.Encoding.utf8) {
            characteristic?.service.peripheral.writeValue(data, for: characteristic!, type: .withResponse)
        }
    }
    
    @IBAction func notifyBtnClick(_ sender: Any) {
        characteristic?.service.peripheral.setNotifyValue(!characteristic!.isNotifying, for: characteristic!)
        let title = characteristic!.isNotifying ? "Notify" : "UnNotify"
        notifyBtn.setTitle(title, for: .normal)
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
