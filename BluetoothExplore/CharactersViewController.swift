//
//  CharactersViewController.swift
//  BluetoothExplore
//
//  Created by TrinaSolar on 2020/1/3.
//  Copyright © 2020 DevQiaoYu. All rights reserved.
//

import UIKit
import CoreBluetooth

class CharactersViewController: UIViewController {

    var service: CBService?
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), style: .grouped)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "characteristics")
        return table
    }()
    
    var connectL: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "characteristics"
        view.backgroundColor = UIColor.white
        view.addSubview(tableView)
        
        let item = UIBarButtonItem(customView: connectL)
        self.navigationItem.rightBarButtonItem = item
        
        service?.peripheral.discover(service: service!, {
            self.tableView.reloadData()
        })
        service?.peripheral.connectBlock = { (state) in
            self.updateConnectState()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateConnectState()
    }
    
    func updateConnectState() {
        switch self.service!.peripheral.state {
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension CharactersViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let characteristics = service?.characteristics {
            return characteristics.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "characteristics", for: indexPath)
        if let characteristics = service?.characteristics {
            let characteristic = characteristics[indexPath.row]
            cell.textLabel?.text = characteristic.uuid.description
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let characteristics = service?.characteristics {
            let characteristic = characteristics[indexPath.row]
            let vc = CharacteristicDetailViewController()
            vc.characteristic = characteristic
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
