//
//  SettingViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 12/13/23.
//

import UIKit

struct settingOption{
    let title: String
    let segue: String
}

protocol settingViewDelegate {
    func addProfilePicture()
}

class SettingViewController: UIViewController {
    @IBOutlet weak var profileImgView: UIImageView!
    @IBOutlet weak var profileView: UIView!
    @IBOutlet weak var settingTableView: UITableView!
    @IBOutlet weak var fullNameLbl: UILabel!
    
    let settingOptions = [settingOption(title: "Health Details", segue: "ProfilePageSegue"),
                          settingOption(title: "Authorize Health Data", segue: "AuthorizePageSegue"),
                          settingOption(title: "Share Report", segue: "PDFPageSegue")]
    
    let userData = ViewModels.userData
    var isDetailedView = false
    var delegate: settingViewDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        settingTableView.delegate = self
        settingTableView.dataSource = self
        
        if isDetailedView {
            let rightBarButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissView))
            self.navigationItem.rightBarButtonItem = rightBarButton
        }
        
        fullNameLbl.text = "\(userData.firstName ?? "") \(userData.lastName ?? "")"
        
        profileView.layer.cornerRadius = profileView.frame.size.width/2
        
        let imgTapGesture = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImgView.addGestureRecognizer(imgTapGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let image = ViewModels.profileImage {
            profileImgView.image = image
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isDetailedView {
            delegate?.addProfilePicture()
        }
    }
    
    @objc func dismissView() {
        self.dismiss(animated: true)
    }
    
    @objc func profileImageTapped() {
        performSegue(withIdentifier: "ProfilePageSegue", sender: self)
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

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath)
        
        cell.textLabel?.text = settingOptions[indexPath.row].title
        
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: settingOptions[indexPath.row].segue, sender: self)
    }
}
