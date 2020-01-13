//
//  CentralViewController.swift
//  BluetoothExplore
//
//  Created by 乔羽 on 2020/1/2.
//  Copyright © 2020 DevQiaoYu. All rights reserved.
//

import UIKit
import CoreBluetooth

class CentralViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scanBtn: UIBarButtonItem!
    

    override func viewDidLoad() {
        super.viewDidLoad()

        BLECentralManager.shareInstance.scanBlock = {
            self.tableView.reloadData()
        }
        BLECentralManager.shareInstance.stateUpdateBlock = { (state) in
            
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.reloadData()
    }
    
    
    @IBAction func scanBtnClick(_ sender: Any) {
        if BLECentralManager.shareInstance.isScaning! {
            BLECentralManager.shareInstance.stopScan()
            scanBtn.title = "scan"
        } else {
//            BLECentralManager.shareInstance.scan([CBUUID(string: Service_UUID)])
            BLECentralManager.shareInstance.scan()
            scanBtn.title = "stop"
        }
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

extension CentralViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BLECentralManager.shareInstance.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: perTableViewCell = tableView.dequeueReusableCell(withIdentifier: "peripheralList", for: indexPath) as! perTableViewCell
        let per = BLECentralManager.shareInstance.peripherals[indexPath.row]
        if let rssi = per.RSSI?.intValue {
            cell.RSSILabel.text = String(rssi)
        }
        cell.nameL.text = per.name ?? "Unnamed"
        cell.identifyL.text = per.identifier.uuidString
        switch per.state {
        case .disconnected:
            cell.stateL.text = "未连接"
            cell.stateL.textColor = .gray
        case .connected:
            cell.stateL.text = "已连接"
            cell.stateL.textColor = .green
        case .connecting:
            cell.stateL.text = "连接中"
            cell.stateL.textColor = .orange
        default:
            cell.stateL.text = ""
        }
        per.connectBlock = { (state) in
            self.tableView.reloadData()
            switch state {
            case .connected:
                print(state)
            default:
                print(state)
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let per = BLECentralManager.shareInstance.peripherals[indexPath.row]
        switch per.state {
        case .connected:
            let vc = ServicesViewController()
            vc.peripheral = per
            navigationController?.pushViewController(vc, animated: true)
        case .connecting:
            return
        case .disconnected:
            BLECentralManager.shareInstance.connectToPeripheral(per)
            print("start connect")
        default:
            return
        }
    }
    
}
