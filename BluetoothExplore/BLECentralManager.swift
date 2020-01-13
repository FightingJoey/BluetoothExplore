//
//  BLECentralManager.swift
//  BluetoothExplore
//
//  Created by 乔羽 on 2020/1/2.
//  Copyright © 2020 DevQiaoYu. All rights reserved.
//

import CoreBluetooth
import UIKit

enum BLEState {
    case unknown
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}

enum BLEConnectState {
    case connecting
    case connected
    case fail
    case disConnect
}

typealias BLEConnectStateBlock = ((BLEConnectState) -> ())
typealias EmptyBlock = (() -> ())
typealias DataBlock = ((Data) -> ())

class BLECentralManager: NSObject {
    
    static let shareInstance = BLECentralManager()
    private var centralManager: CBCentralManager?
    private var peripheralList: Array<CBPeripheral> = []
    private var connectedPeripheralList: Array<CBPeripheral> = []
    
    var isScaning: Bool? {
        get {
            return centralManager?.isScanning
        }
    }
    var peripherals: Array<CBPeripheral> {
        get {
            return peripheralList
        }
    }
    var state: BLEState?
    var BLEStateMsg: String = ""
    var overtime: Int = 5
    var scanBlock: (() -> ())?
    var stateUpdateBlock: ((BLEState) -> ())?
    
    private override init() {
        super.init()
        centralManager = CBCentralManager.init(delegate: self, queue: DispatchQueue.global())
        
        // 检索已连接的外设
        // centralManager?.retrieveConnectedPeripherals(withServices: <#T##[CBUUID]#>)
        // 检索外设
        // centralManager?.retrievePeripherals(withIdentifiers: <#T##[UUID]#>)
        
    }
    
    public func scan(_ services: Array<CBUUID>? = nil) {
        peripheralList = []
        centralManager?.scanForPeripherals(withServices: services, options: nil)
    }
    
    public func stopScan() {
        centralManager?.stopScan()
    }
    
    /** 连接外设 */
    public func connectToPeripheral(_ per: CBPeripheral) {
        centralManager?.connect(per, options: nil)
        DispatchQueue.main.async {
            if let block = per.connectBlock {
                block(.connecting)
            }
        }
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + .seconds(overtime)) {
            if per.state == .connecting {
                print("连接超时")
                self.cancelConnectWithPeripheral(per)
            }
        }
    }
    /** 取消连接外设 */
    public func cancelConnectWithPeripheral(_ per: CBPeripheral) {
        centralManager?.cancelPeripheralConnection(per)
    }
    
}

// MARK: CBCentralManagerDelegate
extension BLECentralManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
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
            block(state!)
        }
        print(BLEStateMsg)
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        peripheral.RSSI = RSSI;
        if !peripheralList.contains(peripheral) {
            peripheralList.append(peripheral)
        } else {
            for per in peripheralList {
                if per.identifier == peripheral.identifier {
                    per.RSSI = peripheral.RSSI
                }
            }
        }
        if let block = scanBlock {
            DispatchQueue.main.sync {
                block()
            }
        }
        print(RSSI)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("connect success")
        if !connectedPeripheralList.contains(peripheral) {
            connectedPeripheralList.append(peripheral)
        }
        if let block = peripheral.connectBlock {
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.25) {
                DispatchQueue.main.sync {
                    block(.connected)
                }
            }
        }
        peripheral.delegate = self
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("connect failed")
        if let block = peripheral.connectBlock {
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.25) {
                DispatchQueue.main.sync {
                    block(.fail)
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("disconnect")
        if let block = peripheral.connectBlock {
            DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 0.25) {
                DispatchQueue.main.sync {
                    block(.disConnect)
                }
            }
        }
        if connectedPeripheralList.contains(peripheral) {
            print("需要重新连接")
            DispatchQueue.main.sync {
                let alert = UIAlertController(title: "已断开连接", message: "是否重新连接？", preferredStyle: .alert)
                let action = UIAlertAction(title: "重新连接", style: .default) { (action) in
                    BLECentralManager.shareInstance.connectToPeripheral(peripheral)
                }
                let cancel = UIAlertAction(title: "取消", style: .cancel) { (action) in
                    if let index = self.connectedPeripheralList.firstIndex(of: peripheral) {
                        self.connectedPeripheralList.remove(at: index)
                    }
                    print(self.connectedPeripheralList.count)
                }
                alert.addAction(action)
                alert.addAction(cancel)
                UIApplication.shared.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}

// MARK: CBPeripheral

private var rssiKey: String = "rssi"
private var connectBlockKey: String = "connectBlockKey"
private var advertisementDataKey: String = "advertisementDataKey"
private var discoverServicesBlockKey: String = "discoverServicesBlockKey"
private var discoverCharacteristicsBlockKey: String = "discoverCharacteristicsBlockKey"
private var updateValueBlockKey: String = "updateValueBlockKey"
extension CBPeripheral {
    var RSSI: NSNumber? {
        get {
            return objc_getAssociatedObject(self, &rssiKey) as? NSNumber
        }
        set {
            objc_setAssociatedObject(self,
                                     &rssiKey, newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    var connectBlock: BLEConnectStateBlock? {
        get {
            return objc_getAssociatedObject(self, &connectBlockKey) as? BLEConnectStateBlock
        }
        set {
            objc_setAssociatedObject(self,
                                     &connectBlockKey, newValue,
                                     .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    var advertisementData: [String : Any]? {
        get {
            return objc_getAssociatedObject(self, &advertisementDataKey) as? [String : Any]
        }
        set {
            objc_setAssociatedObject(self,
                                     &advertisementDataKey, newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var discoverServicesBlock: EmptyBlock? {
        get {
            return objc_getAssociatedObject(self, &discoverServicesBlockKey) as? EmptyBlock
        }
        set {
            objc_setAssociatedObject(self,
                                     &discoverServicesBlockKey, newValue,
                                     .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    var discoverCharacteristicsBlock: EmptyBlock? {
        get {
            return objc_getAssociatedObject(self, &discoverCharacteristicsBlockKey) as? EmptyBlock
        }
        set {
            objc_setAssociatedObject(self,
                                     &discoverCharacteristicsBlockKey, newValue,
                                     .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    var updateValueBlock: DataBlock? {
        get {
            return objc_getAssociatedObject(self, &updateValueBlockKey) as? DataBlock
        }
        set {
            objc_setAssociatedObject(self,
                                     &updateValueBlockKey, newValue,
                                     .OBJC_ASSOCIATION_COPY_NONATOMIC)
        }
    }
    
    /** 扫描该外设的服务 */
    func discover(_ block: @escaping EmptyBlock, _ services: Array<CBUUID>? = nil) {
        discoverServicesBlock = block
        discoverServices(services)
    }
    /** 扫描该服务的特征 */
    func discover(service: CBService, _ block: @escaping EmptyBlock, _ characteristics: Array<CBUUID>? = nil) {
        discoverCharacteristicsBlock = block
        discoverCharacteristics(characteristics, for: service)
    }
    /** 获取该特征的数据 */
    func readValue(_ characteristic: CBCharacteristic, _ block: @escaping DataBlock) {
        updateValueBlock = block
        readValue(for: characteristic)
    }
    /** 是否订阅该外设的特征 */
    func setNotifyValue(_ enabled: Bool, _ characteristic: CBCharacteristic) {
        setNotifyValue(enabled, for: characteristic)
    }
}

// MARK: CBPeripheralDelegate
extension BLECentralManager: CBPeripheralDelegate {
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        
    }
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        print("did read RSSI")
    }
    /** 扫描服务  */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let err = error {
            print("服务扫描失败 %s", err.localizedDescription)
        } else {
            if let services = peripheral.services {
                for service in services {
                    print("外设中的服务有：\(service)")
                }
            }
            
            if let block = peripheral.discoverServicesBlock {
                DispatchQueue.main.sync {
                    block()
                }
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("modify services")
    }
    /** 扫描特征  */
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let err = error {
            print("特征扫描失败 %s", err.localizedDescription)
        } else {
            if let characteristics = service.characteristics {
                for character in characteristics {
                    print("外设中的特征有：\(character)")
                }
            }
            if let block = peripheral.discoverCharacteristicsBlock {
                DispatchQueue.main.sync {
                    block()
                }
            }
        }
    }
    /** 向外设写入数据回调 */
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("写入数据")
    }
    /** 接收到外设发送的数据 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let block = peripheral.updateValueBlock, let value = characteristic.value {
            DispatchQueue.main.sync {
                block(value)
            }
        }
    }
    /** 订阅状态 */
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let err = error {
            print("central订阅characteristic失败: \(err)")
            return
        }
        if characteristic.isNotifying {
            print("central订阅characteristic成功")
        } else {
            print("central取消订阅characteristic")
        }
    }
}
