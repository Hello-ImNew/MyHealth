//
//  FriendsViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 9/4/24.
//

import UIKit

struct Friend: Decodable {
    let friendID: String
    let isShareAllowed: Bool
    
    enum CodingKeys: String, CodingKey {
        case user_ID = "user_ID"
        case requestID = "friend_ID"
        case isShareAllowed = "allowed_sharing"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let isShareAllowed = try container.decode(Int.self, forKey: .isShareAllowed)
        self.isShareAllowed = isShareAllowed != 0
        
        let userID = try container.decode(String.self, forKey: .user_ID)
        let requestID = try container.decode(String.self, forKey: .requestID)
        let id = ViewModels.userID
        if userID != id {
            self.friendID = userID
            return
        }
        
        if requestID != id {
            self.friendID = requestID
            return
        }
        
        self.friendID = ""
    }
}

struct FriendInfo: Decodable {
    let firstName: String
    let lastName: String
    let imagePath: String?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case imagePath = "image_path"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.imagePath = try? container.decode(String.self, forKey: .imagePath)
    }
}

class FriendsViewController: UIViewController {
    
    @IBOutlet weak var friendRequestBtn: UIButton!
    @IBOutlet weak var addFriendBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var friendRequests: [String] = []
    var friendList: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
        viewSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if ViewModels.isOnline {
            checkRequest() { [self] success, result in
                DispatchQueue.main.async {
                    if success,
                       let results = result {
                        if results.isEmpty {
                            self.friendRequestBtn.isHidden = true
                            return
                        } else {
                            let requestNum = results.count
                            self.friendRequests = results
                            self.setupRequestBtn(self.friendRequests.count)
                        }
                    }
                }
            }
            
            getFriendsList() { results in
                if let results = results {
                    self.friendList = results
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    func viewSetup() {
        addFriendBtn.layer.cornerRadius = 15
        addFriendBtn.clipsToBounds = true
        
        friendRequestBtn.layer.cornerRadius = 15
        friendRequestBtn.clipsToBounds = true
    }
    
    func setupRequestBtn(_ requestCount: Int) {
        let circleView = UIView()
        circleView.layer.cornerRadius = 15
        circleView.clipsToBounds = true
        circleView.backgroundColor = .systemRed
        circleView.translatesAutoresizingMaskIntoConstraints = false
        
        let requestNumLbl = UILabel()
        requestNumLbl.textAlignment = .center
        var requestStr: String
        if requestCount < 100 {
            requestStr = "\(requestCount)"
        } else {
            requestStr = "99+"
        }
        requestNumLbl.text = requestStr
        requestNumLbl.textColor = .white
        requestNumLbl.font = .systemFont(ofSize: 15)
        requestNumLbl.translatesAutoresizingMaskIntoConstraints = false
        circleView.addSubview(requestNumLbl)
        
        NSLayoutConstraint.activate([
            requestNumLbl.centerXAnchor.constraint(equalTo: circleView.centerXAnchor),
            requestNumLbl.centerYAnchor.constraint(equalTo: circleView.centerYAnchor)
        ])
        
        friendRequestBtn.addSubview(circleView)
        
        NSLayoutConstraint.activate([
            circleView.centerYAnchor.constraint(equalTo: friendRequestBtn.centerYAnchor),
            circleView.trailingAnchor.constraint(equalTo: friendRequestBtn.trailingAnchor, constant: -3),
            circleView.widthAnchor.constraint(equalToConstant: 30),
            circleView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    func checkRequest(_ completion: @escaping (Bool, [String]?) -> Void) {
        let link = serviceURL + "get_request.php"
        guard let url = URL(string: link) else {
            print("Cannot connect to web service.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = ["user_ID": ViewModels.userID!]
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
        } catch {
            print("Error encoding data: \(error)")
            completion(false, nil)
            return
        }
        
        ViewModels.sharedSession.dataTask(with: request) {(data, response, error) in
            guard error == nil,
                  let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                self.showAlert(title: "Connection Error", message: error!.localizedDescription)
                completion(false, nil)
                return
            }
            
            let str = String(data: data, encoding: .utf8)
            
            guard (200...299).contains(httpResponse.statusCode) else {
                self.showAlert(title: "Server Error", message: String(data: data, encoding: .utf8) ?? "")
                return
            }
            
            do {
                if let jsonArray = try JSONSerialization.jsonObject(with: data, options: []) as? [String] {
                    completion(true, jsonArray)
                } else {
                    print("Failed to parse JSON data")
                    completion(false, nil)
                }
            } catch {
                print("JSON decoding error: \(error.localizedDescription)")
            }
        }.resume()
    }
    
    func getFriendsList(_ completion: @escaping ([String]?) -> Void) {
        let link = serviceURL + "get_friends.php"
        guard let url = URL(string: link) else {
            print("Cannot connect to web setvice.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = ["user_ID": ViewModels.userID!]
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
        } catch {
            print("Error encoding data: \(error)")
            completion(nil)
            return
        }
        
        ViewModels.sharedSession.dataTask(with: request) {(data, response, error) in
            guard error == nil,
                  let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                self.showAlert(title: "Connection Error", message: error!.localizedDescription)
                completion(nil)
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                self.showAlert(title: "Server Error", message: String(data: data, encoding: .utf8) ?? "")
                completion(nil)
                return
            }
            print(String(data: data, encoding: .utf8) ?? "")
            do {
                let list = try JSONDecoder().decode([Friend].self, from: data)
                let friends = list.map({$0.friendID})
                completion(friends)
            } catch {
                print("Error encoding data: \(error)")
                completion(nil)
                return
            }
        }.resume()
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "FriendRequestSegue" {
            let destinationVC = segue.destination as? FriendRequestListViewController
            destinationVC?.requests = friendRequests
        }
    }
    

}

extension FriendsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func getFriendInfo(for id: String, _ completion: @escaping (FriendInfo?) -> Void) {
        let link = serviceURL + "get_friend_info.php"
        guard let url = URL(string: link) else {
            print("Cannot connect to web server")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = ["user_ID": id]
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
        } catch {
            print("Error encoding data: \(error)")
            completion(nil)
            return
        }
        
        ViewModels.sharedSession.dataTask(with: request) {(data, response, error) in
            guard error == nil,
                  let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                self.showAlert(title: "Connection Error", message: error!.localizedDescription)
                completion(nil)
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                self.showAlert(title: "Server Error", message: String(data: data, encoding: .utf8) ?? "")
                completion(nil)
                return
            }
            print(String(data: data, encoding: .utf8) ?? "")
            do {
                let info = try JSONDecoder().decode(FriendInfo.self, from: data)
                completion(info)
            } catch {
                print("Error encoding data: \(error)")
                completion(nil)
                return
            }
        }.resume()
        
    }
   
    func getImage(path: String, _ completion: @escaping (UIImage?) -> Void) {
        let urlString = serviceURL + path
        let url = URL(string: urlString)
        
        guard let url = url else {
            print("Cannot connect to website.")
            completion(nil)
            return
        }
        
        ViewModels.sharedSession.dataTask(with: url) { (data, response, error) in
            
            guard let data = data,
                  error == nil else {
                print("Error connecting to server \(error!)")
                completion(nil)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("Invalid Response.")
                completion(nil)
                return
            }
            
            let image = UIImage(data: data)
            completion(image)
        }.resume()
    }
     
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FriendCell", for: indexPath) as! FriendListTableViewCell
        
        let friendID = friendList[indexPath.row]
        
        getFriendInfo(for: friendID, { result in
            if let result = result {
                let name = result.firstName + " " + result.lastName
                let path = result.imagePath
                
                DispatchQueue.main.async {
                    cell.nameLbl.text = name
                }
                if let path = path {
                    self.getImage(path: path, {image in
                        if let image = image {
                            DispatchQueue.main.async {
                                cell.pfpPic.image = image
                            }
                        }
                    })
                }
            }
        })
        
        return cell
    }
    
    
}
