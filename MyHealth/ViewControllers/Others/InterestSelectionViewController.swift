//
//  InterestSelectionViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 6/27/24.
//

import UIKit

class InterestSelectionViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let interestAreas = ViewModels.interestAreas
    let maxSelection = 3
    var selectedRow = Set<Int>()
    var account: Account!
    
    let columnLayout = ColumnFlowLayout(cellsPerRow: 3,
                                        minimumInteritemSpacing: 10,
                                        minimumLineSpacing: 10,
                                        sectionInset: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.collectionViewLayout = columnLayout
        collectionView.contentInsetAdjustmentBehavior = .always
        overrideUserInterfaceStyle = .light
    }
    
    func toMainScreen() {        
        guard let window = self.view.window else {
            return
        }
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarViewController = mainStoryboard.instantiateViewController(withIdentifier: "MainTabBarView")
        window.rootViewController = tabBarViewController
        window.makeKeyAndVisible()
        
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromRight
        transition.duration = 0.3
        window.layer.add(transition, forKey: kCATransition)
    }
    
    func setSelectedInterest() {
        var healthTypes = Set<String>()
        for i in selectedRow {
            for type in interestAreas[i].dataTypes {
                healthTypes.insert(type)
            }
        }
        
        let types = Array(healthTypes)
        let link = newServiceURL + "fav_data/selected_interest_area.php"
        
        guard let url = URL(string: link) else  {
            print("Cannot connect to web service.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = [
                "user_ID": ViewModels.userID!,
                "types": types
            ] as [String : Any]
            let jsondata = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsondata
        } catch {
            print("Error encoding data: \(error)")
            return
        }
        
        ViewModels.sharedSession.dataTask(with: request) {(data, response, error) in
            guard error == nil,
                  let data = data else {
                print("Error: \(error!)")
                self.showAlert(title: "Connection Error", message: error!.localizedDescription)
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse,
               !(200...299).contains(httpResponse.statusCode) {
                print(String(data: data, encoding: .utf8) ?? "")
                return
            }
            
            ViewModels.userData.isInterestSelected = true
            ViewModels.favHealthTypes = types
            DispatchQueue.main.async {
                if let account = self.account {
                    ViewModels.saveAccount(account)
                }
                self.toMainScreen()
            }
            
        }.resume()
    }
    
    @IBAction func InterestSelected(_ sender: Any) {
        setSelectedInterest()
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

extension InterestSelectionViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return interestAreas.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InterestAreaCell", for: indexPath) as! HealthAreaCollectionViewCell
        
        cell.areaLbl.text = interestAreas[indexPath.row].name
        cell.backgroundColor = .lightGray.withAlphaComponent(0.5)
        cell.layer.borderColor = UIColor.gray.cgColor
        cell.layer.borderWidth = 5
        cell.layer.cornerRadius = 15
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        let value = indexPath.row
        if selectedRow.contains(value) {
            cell?.layer.borderColor = UIColor.gray.cgColor
            selectedRow.remove(value)
            return
        }
        
        if selectedRow.count < maxSelection {
            cell?.layer.borderColor = UIColor.systemGreen.cgColor
            selectedRow.insert(value)
        }
    }
    
//    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
//        let cell = collectionView.cellForItem(at: indexPath)
//        cell?.layer.borderColor = UIColor.gray.cgColor
//    }
}
