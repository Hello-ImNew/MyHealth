//
//  AddFriendTableViewCell.swift
//  MyHealth
//
//  Created by Bao Bui on 10/7/24.
//

import UIKit

class AddFriendTableViewCell: UITableViewCell {

    @IBOutlet weak var pfpView: UIView!
    @IBOutlet weak var pfpImage: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var addBtn: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        DispatchQueue.main.async {
            self.pfpView.layer.cornerRadius = self.pfpView.frame.height / 2
            self.pfpView.clipsToBounds = true
        }
    }
    

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
