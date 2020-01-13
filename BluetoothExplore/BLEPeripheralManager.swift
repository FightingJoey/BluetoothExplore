//
//  BLEPeripheralManager.swift
//  BluetoothExplore
//
//  Created by TrinaSolar on 2020/1/3.
//  Copyright © 2020 DevQiaoYu. All rights reserved.
//

import UIKit
import CoreBluetooth

let Service_UUID: String = "CDD1"
let Characteristic_UUID: String = "CDD2"

class BLEPeripheralManager: NSObject {
    
    static let shareInstance = BLEPeripheralManager()
    
    private var peripheralManager: CBPeripheralManager?
    
    var state: BLEState?
    var BLEStateMsg: String = ""
    var stateUpdateBlock: ((BLEState) -> ())?
    var receiveReadBlock: ((CBATTRequest)->())?
    var receiveWriteBlock: ((CBATTRequest)->())?
    
    private override init() {
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: DispatchQueue.global(), options: nil)
    }
    
    public func add(_ service: CBMutableService) {
        peripheralManager?.add(service)
    }
    
    public func startAdvertising(_ advertisementData: [String : Any]?) {
        peripheralManager?.startAdvertising(advertisementData)
    }
    public func updateValue(_ value: Data, for characteristic: CBMutableCharacteristic, onSubscribedCentrals centrals: [CBCentral]?) {
        peripheralManager?.updateValue(value, for: characteristic, onSubscribedCentrals: centrals)
    }
    public func respond(to request: CBATTRequest, withResult result: CBATTError.Code) {
        peripheralManager?.respond(to: request, withResult: result)
    }
}

extension BLEPeripheralManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            state = .unknown
            BLEStateMsg = "状态未知"
        case .resetting:
            state = .resetting
            BLEStateMsg = "连接断开，即将重置"
        case .unsupported:
            state = .unsupported
            BLEStateMsg = "该平台不支持蓝牙"
        case .unauthorized:
            state = .unauthorized
            BLEStateMsg = "未授权蓝牙使用"
        case .poweredOff:
            state = .poweredOff
            BLEStateMsg = "蓝牙关闭"
        case .poweredOn:
            state = .poweredOn
            BLEStateMsg = "蓝牙可用"
        default:
            state = .unknown
            BLEStateMsg = ""
        }
        if let block = stateUpdateBlock {
            DispatchQueue.main.sync {
                block(state!)
            }
        }
        print(BLEStateMsg)
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("开始广播")
    }
    
    /** 中心设备读取数据的时候回调 */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        if let block = receiveReadBlock {
            DispatchQueue.main.sync {
                block(request)
            }
        }
    }
    
    /** 中心设备写入数据 */
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        if let block = receiveWriteBlock, let request = requests.last {
            DispatchQueue.main.sync {
                block(request)
            }
        }
    }
    
    /** 订阅成功回调 */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("characteristic被central订阅成功")
    }
    
    /** 取消订阅回调 */
    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("characteristic被central取消订阅")
    }
}
