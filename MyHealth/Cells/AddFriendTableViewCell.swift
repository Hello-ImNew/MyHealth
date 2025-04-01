//
//  AddFriendTableViewCell.swift
//  MyHealth
//
//  Created by Bao Bui on 10/7/24.
//

import UIKit
protocol AddFriendCellDelegate: AnyObject {
    func showAlert(title: String, message: String)
}

class AddFriendTableViewCell: UITableViewCell {

    @IBOutlet weak var pfpView: UIView!
    @IBOutlet weak var pfpImage: UIImageView!
    @IBOutlet weak var nameLbl: UILabel!
    @IBOutlet weak var addBtn: UIButton!
    
    weak var parentVC: AddFriendCellDelegate?
    var searchResult: SearchResult!
    
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
    
    
    @IBAction func addButtonTapped(_ sender: Any) {
        (sender as? UIButton)?.isEnabled = false
        let link = newServiceURL + "friend/send_request.php"
        guard let url = URL(string: link) else {
            print("Cannot connect to website.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = [
                "user_ID" : ViewModels.userID!,
                "request_ID" : searchResult.userID
            ]
            
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
        } catch {
            print("Error encoding data: \(error)")
            return
        }
        
        ViewModels.sharedSession.dataTask(with: request) {(data, response, error) in
            DispatchQueue.main.async {
                (sender as? UIButton)?.isEnabled = true
            }
            
            guard error == nil else {
                self.parentVC?.showAlert(title: "Connection error", message: error!.localizedDescription)
                return
            }
            
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                self.parentVC?.showAlert(title: "Data task error", message: "Data is empty or response error")
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 409 {
                    print("Request is already made")
                } else {
                    let strError = String(data: data, encoding: .utf8) ?? ""
                    print("Server Error: \(strError)")
                    self.parentVC?.showAlert(title: "Server Error", message: strError)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.addBtn.setTitle("Requested", for: .normal)
                self.addBtn.isEnabled = false
            }
        }.resume()
    }
}
