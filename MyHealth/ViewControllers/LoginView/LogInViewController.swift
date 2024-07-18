//
//  LogInViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 6/4/24.
//

import UIKit

class LogInViewController: UIViewController {
    
    @IBOutlet weak var usernameTxt: UITextField!
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var failLbl: UILabel!
    @IBOutlet weak var signInBtn: UIButton!
    @IBOutlet weak var signUpBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        failLbl.layer.cornerRadius = 10
        failLbl.layer.borderWidth = 1
        failLbl.layer.borderColor = UIColor.red.cgColor
        failLbl.layer.masksToBounds = true
        
        if let savedAccount = ViewModels.getSavedAccount() {
            signin(username: savedAccount.username, password: savedAccount.password, { success in
                if success {
                    ViewModels.getUserData() { data in
                        if let data = data {
                            DispatchQueue.main.async {
                                self.successSignedIn(with: data)
                            }
                        }
                    }
                }
            })
        }
    }
    
    func successSignedIn(with data: UserData) {
        ViewModels.userData = data
        guard let window = self.view.window else {
            return
        }
        
        let transition = CATransition()
        transition.type = .push
        transition.subtype = .fromRight
        transition.duration = 0.3
        window.layer.add(transition, forKey: kCATransition)
        
        guard data.isInterestSelected else {
            let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let interestVC = mainStoryboard.instantiateViewController(withIdentifier: "InterestAreasVC")
            let interestNavVC = UINavigationController(rootViewController: interestVC)
            window.rootViewController = interestNavVC
            window.makeKeyAndVisible()
            
//            UIView.transition(with: window, duration: 0.3, animations: {
//                let moveLeft = CGAffineTransform(translationX: -(self.view.bounds.width), y: 0.0)
//                interestVC.view.transform = moveLeft
//                
//            })
            return
        }
        
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let tabBarViewController = mainStoryboard.instantiateViewController(withIdentifier: "MainTabBarView")
        window.rootViewController = tabBarViewController
        window.makeKeyAndVisible()
    }
    
    func signin(username: String, password: String, _ completion: @escaping (Bool) -> Void) {
        let link = serviceURL + "sign_in.php"
        let url = URL(string: link)
        guard let url = url else {
            print("Cannot connect to web service.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = [
                "username": username,
                "password": password
            ]
            
            let jsondata = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsondata
        } catch {
            print("Error encoding data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) {(data, response, error) in
            guard error == nil,
                  let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                print("Error: \(error!)")
                completion(false)
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                if httpResponse.statusCode == 401 {
                    DispatchQueue.main.async {
                        self.failLbl.isHidden = false
                        print("Incorrent username or password.")
                    }
                }
                print(String(data: data, encoding: .utf8) ?? "")
                completion(false)
                return
            }
            
            let id = String(data: data, encoding: .utf8) ?? ""
            if isValidUUID(for: id) {
                ViewModels.userID = id
                print(id)
                completion(true)
            } else {
                self.showAlert(title: "Error", message: "Error encouter when login.")
                completion(false)
            }
        }.resume()
    }
    
    @IBAction func signInTapped(_ sender: Any) {
        guard let password = passwordTxt.text,
              let username = usernameTxt.text else {
                  return
              }
        
        signin(username: username, password: password) { success in
            if success {
                ViewModels.getUserData() { data in
                    if let data = data {
                        DispatchQueue.main.async {
                            let account = Account(username: username, password: password)
                            ViewModels.saveAccount(account)
                            
                            self.successSignedIn(with: data)
                        }
                    }
                }
            }
        }
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
