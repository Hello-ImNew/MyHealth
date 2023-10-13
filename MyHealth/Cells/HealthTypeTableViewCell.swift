//
//  HealthTypeTableViewCell.swift
//  MyHealth
//
//  Created by Bao Bui on 10/3/23.
//

import UIKit

class HealthTypeTableViewCell: UITableViewCell {

    @IBOutlet weak var txtTitle: UILabel!
    @IBOutlet weak var imgIcon: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
