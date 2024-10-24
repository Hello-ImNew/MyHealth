//
//  FriendListTableViewCell.swift
//  MyHealth
//
//  Created by Bao Bui on 9/4/24.
//

import UIKit

class FriendListTableViewCell: UITableViewCell {
   
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var pfpPicView: UIView!
    @IBOutlet weak var pfpPic: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        DispatchQueue.main.async {
            self.pfpPicView.layer.cornerRadius = self.pfpPicView.frame.width / 2
            self.pfpPicView.clipsToBounds = true
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
