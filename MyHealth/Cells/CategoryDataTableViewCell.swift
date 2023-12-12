//
//  CategoryDataTableViewCell.swift
//  MyHealth
//
//  Created by Bao Bui on 12/6/23.
//

import UIKit

class CategoryDataTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgIcon: UIImageView!
    @IBOutlet weak var txtName: UILabel!
    @IBOutlet weak var txtData: UILabel!
    @IBOutlet weak var txtTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
