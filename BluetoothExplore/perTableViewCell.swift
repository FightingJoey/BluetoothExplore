//
//  perTableViewCell.swift
//  BluetoothExplore
//
//  Created by 乔羽 on 2020/1/2.
//  Copyright © 2020 DevQiaoYu. All rights reserved.
//

import UIKit

class perTableViewCell: UITableViewCell {

    @IBOutlet weak var nameL: UILabel!
    @IBOutlet weak var identifyL: UILabel!
    @IBOutlet weak var RSSILabel: UILabel!
    @IBOutlet weak var stateL: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
