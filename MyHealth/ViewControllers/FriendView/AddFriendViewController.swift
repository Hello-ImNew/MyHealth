//
//  AddFriendViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 10/1/24.
//

import UIKit
struct SearchResult: Decodable {
    let firstName: String
    let lastName: String
    let imgPath: String?
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
        case imgPath = "image_path"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.firstName = try container.decode(String.self, forKey: .firstName)
        self.lastName = try container.decode(String.self, forKey: .lastName)
        self.imgPath = try? container.decodeIfPresent(String.self, forKey: .imgPath)
    }
}

class AddFriendViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    var searchingTask: URLSessionDataTask?
    var isPromptEntered = false
    var searchResults: [SearchResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tableView.dataSource = self
        tableView.delegate = self
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

extension AddFriendViewController: UITableViewDelegate, UITableViewDataSource {
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
        if isPromptEntered {
            return searchResults.count
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if !isPromptEntered {
            return nil
        } else {
            let title = "Search Result"
            let headerView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: tableView.frame.width, height: 50))
            
            let label = UILabel(frame: .init(x: 5, y: 5,
                                             width: headerView.frame.width - 10,
                                             height: headerView.frame.height - 10))
            label.text = title
            label.font = .systemFont(ofSize: 25)
            label.textColor = .secondaryLabel
            label.center = headerView.center
            
            headerView.addSubview(label)
            headerView.backgroundColor = tableView.backgroundColor
            return headerView
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isPromptEntered {
            return 50
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddFriendCell", for: indexPath) as! AddFriendTableViewCell
        let result = searchResults[indexPath.row]
        
        let name = result.firstName + " " + result.lastName
        cell.nameLbl.text = name
        if let path = result.imgPath {
            getImage(path: path, { image in
                if let image = image {
                    cell.pfpImage.image = image
                }
            })
        }
        
        return cell
    }
    
}

extension AddFriendViewController: UISearchBarDelegate {
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        var task: URLSessionDataTask? = nil
        if let task = task {
            cancelSearch(task)
        }
        
        if let searchStr = searchBar.text,
           searchStr.count >= 3 {
            isPromptEntered = true
            task = startSearching(searchText: searchStr, completion: {result in
                DispatchQueue.main.async {
                    if let result = result {
                        self.searchResults = result
                        self.tableView.reloadData()
                    }
                }
            })
        } else {
            isPromptEntered = false
        }
    }
    
    func cancelSearch(_ task: URLSessionDataTask) {
        task.cancel()
    }
    
    func startSearching(searchText: String, completion: @escaping ([SearchResult]?) -> Void) -> URLSessionDataTask? {
        let link = serviceURL + "search_friend.php"
        guard let url = URL(string: link) else {
            print("Cannot connect to website.")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = ["key_word" : searchText,
                           "user_ID": ViewModels.userID!]
            let jsonData = try JSONEncoder().encode(payload)
            request.httpBody = jsonData
        } catch {
            print("Error encoding data: \(error)")
            return nil
        }
        
        let task = ViewModels.sharedSession.dataTask(with: request) { (data, response, error) in
            guard error == nil else {
                print("Connection error: \(error!.localizedDescription)")
                self.showAlert(title: "Connection error", message: error!.localizedDescription)
                return
            }
            
            guard let data = data else {
                print("No data returned.")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                let strError = String(data: data, encoding: .utf8) ?? ""
                print("Server Error: \(strError)")
                self.showAlert(title: "Server Error", message: strError)
                return
            }
            
            print(String(data: data, encoding: .utf8) ?? "")
            
            do {
                let result = try JSONDecoder().decode([SearchResult].self, from: data)
                completion(result)
            } catch {
                print("Error encoding data: \(error)")
                completion(nil)
                return
            }
        }
        
        task.resume()
        return task
    }
}
