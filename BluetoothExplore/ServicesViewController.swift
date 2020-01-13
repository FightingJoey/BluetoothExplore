//
//  ServicesViewController.swift
//  BluetoothExplore
//
//  Created by TrinaSolar on 2020/1/3.
//  Copyright © 2020 DevQiaoYu. All rights reserved.
//

import UIKit
import CoreBluetooth

class ServicesViewController: UIViewController {
    
    var peripheral: CBPeripheral?
    
    lazy var tableView: UITableView = {
        let table = UITableView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), style: .grouped)
        table.delegate = self
        table.dataSource = self
        table.register(UITableViewCell.self, forCellReuseIdentifier: "service")
        return table
    }()
    
    var connectL: UILabel = {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
        label.text = ""
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        view.addSubview(tableView)
        
        let item = UIBarButtonItem(customView: connectL)
        self.navigationItem.rightBarButtonItem = item
        updateConnectState()

        peripheral?.discover({
            self.tableView.reloadData()
        })
        peripheral?.connectBlock = { (state) in
            self.updateConnectState()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateConnectState()
    }
    
    func updateConnectState() {
        switch peripheral!.state {
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

}

extension ServicesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let services = peripheral?.services {
            return services.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "service", for: indexPath)
        if let services = peripheral?.services {
            let service = services[indexPath.row]
            cell.textLabel?.text = service.uuid.description
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 44
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let services = peripheral?.services {
            let service = services[indexPath.row]
            let vc = CharactersViewController()
            vc.service = service
            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
}
