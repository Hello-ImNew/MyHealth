//
//  AvailableDataTypeTableViewCell.swift
//  MyHealth
//
//  Created by Bao Bui on 10/6/23.
//

import UIKit

class AvailableDataTypeTableViewCell: UITableViewCell {
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var txtLabel: UILabel!
    @IBOutlet weak var txtData: UILabel!
    @IBOutlet weak var txtDate: UILabel!
    @IBOutlet weak var chartView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
