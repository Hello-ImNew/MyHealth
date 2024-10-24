//
//  RequestTableViewCell.swift
//  MyHealth
//
//  Created by Bao Bui on 9/18/24.
//

import UIKit

protocol RequestCellDelegate: AnyObject {
    func showAlert(title: String, message: String)
    func removeCell(_ cell: RequestTableViewCell)
}

struct requestResponsePayload: Encodable {
    let userID: String
    let requestID: String
    let isAccept: Bool
    
    enum CodingKeys: String, CodingKey {
        case userID = "user_ID"
        case requestID = "request_ID"
        case isAccept = "is_accept"
    }
}

class RequestTableViewCell: UITableViewCell {
    private var _id = ViewModels.userID
    private var _requestID: String = ""
    
    @IBOutlet weak var friendPfpImage: UIImageView!
    @IBOutlet weak var pfpView: UIView!
    @IBOutlet weak var friendName: UILabel!
    @IBOutlet weak var acceptBtn: UIButton!
    @IBOutlet weak var rejectBtn: UIButton!
    
    weak var parentVC: RequestCellDelegate?
    
    var requestID: String {
        set {
            _requestID = newValue
            setupBtns()
        }
        
        get {
            return _requestID
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        DispatchQueue.main.async {
            self.pfpView.layer.cornerRadius = self.pfpView.frame.width / 2
            self.pfpView.clipsToBounds = true
        }
        setupBtns()
    }
    
    func setupBtns() {
        if isValidUUID(for: _id),
           isValidUUID(for: _requestID) {
            acceptBtn.isEnabled = true
            rejectBtn.isEnabled = true
        } else {
            acceptBtn.isEnabled = false
            rejectBtn.isEnabled = false
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func responseRequest(isAccept: Bool, _ completion: @escaping (Bool) -> Void) {
        guard isValidUUID(for: _id),
              isValidUUID(for: _requestID),
              let _id = _id else {
            return
        }
        
        let link = serviceURL + "request_response.php"
        guard let url = URL(string: link) else {
            print("Cannot connect to web server")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = requestResponsePayload(userID: _id, 
                                                 requestID: _requestID,
                                                 isAccept: isAccept)
            
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
        } catch {
            print("Error encoding data: \(error)")
            completion(false)
            return
        }
        
        ViewModels.sharedSession.dataTask(with: request) {(data, response, error) in
            guard error == nil,
                  let data = data else {
                print(error!.localizedDescription)
                self.parentVC?.showAlert(title: "Connection Error", message: error!.localizedDescription)
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                let str = String(data: data, encoding: .utf8) ?? ""
                print(str)
                self.parentVC?.showAlert(title: "Server Error", message: str)
                completion(false)
                return
            }
            
            print(String(data: data, encoding: .utf8) ?? "")
            completion(true)
        }.resume()
    }

    @IBAction func acceptRequest(_ sender: Any) {
        guard isValidUUID(for: _id),
              isValidUUID(for: _requestID) else {
            return
        }
        responseRequest(isAccept: true, { success in
            if success {
                self.parentVC?.removeCell(self)
            }
        })
    }
    
    @IBAction func rejectRequest(_ sender: Any) {
        guard isValidUUID(for: _id),
              isValidUUID(for: _requestID) else {
            return
        }
        responseRequest(isAccept: false, {
            if $0 {
                self.parentVC?.removeCell(self)
            }
        })
    }
}
