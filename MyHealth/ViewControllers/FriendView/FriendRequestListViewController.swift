//
//  FriendRequestListViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 9/18/24.
//

import UIKit



class FriendRequestListViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    var requests: [String]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.delegate = self
        tableView.dataSource = self
        tableView.reloadData()
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FriendRequestListViewController: RequestCellDelegate {
    func removeCell(_ cell: RequestTableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            requests.remove(at: indexPath.row)
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
}

extension FriendRequestListViewController: UITableViewDelegate, UITableViewDataSource {
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
            //print(String(data: data, encoding: .utf8) ?? "")
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
        return requests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath) as! RequestTableViewCell
        
        let userID = requests[indexPath.row]
        cell.requestID = userID
        getFriendInfo(for: userID, { result in
            if let result = result {
                let name = result.firstName + " " + result.lastName
                let path = result.imagePath
                DispatchQueue.main.async {
                    cell.friendName.text = name
                }
                
                if let path = path {
                    self.getImage(path: path, {image in
                        self.getImage(path: path, {image in
                            if let image = image {
                                DispatchQueue.main.async {
                                    cell.friendPfpImage.image = image
                                }
                            }
                        })
                    })
                }
            }
        })
        
        return cell
    }
}
