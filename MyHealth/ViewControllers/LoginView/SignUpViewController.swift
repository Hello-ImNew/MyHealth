//
//  SignUpViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 6/4/24.
//

import UIKit

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var lastNameTxt: UITextField!
    @IBOutlet weak var firstNameTxt: UITextField!
    @IBOutlet weak var usernameTxt: UITextField!
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var confirmTxt: UITextField!
    @IBOutlet weak var errorUsernameLbl: UILabel!
    @IBOutlet weak var errorPasswordLbl: UILabel!
    @IBOutlet weak var errorConfirmLbl: UILabel!
    @IBOutlet weak var errorLastNameLbl: UILabel!
    @IBOutlet weak var errorFirstNameLbl: UILabel!
    
    @IBOutlet weak var lastNameLbl: UILabel!
    @IBOutlet weak var firstNameLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var passwordLbl: UILabel!
    @IBOutlet weak var confirmLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setUpLabel()
    }
    
    func setUpLabel() {
        let attr1 = [NSAttributedString.Key.foregroundColor: UIColor.red,
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        let attr2 = [NSAttributedString.Key.foregroundColor: UIColor.label,
                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
        let requireMark = NSAttributedString(string: "*", attributes: attr1)
        
        let lastNameStr = NSMutableAttributedString(attributedString: requireMark)
        lastNameStr.append(NSAttributedString(string: "Last name", attributes: attr2))
        lastNameLbl.attributedText = lastNameStr
        
        let firstNameStr = NSMutableAttributedString(attributedString: requireMark)
        firstNameStr.append(NSAttributedString(string: "First name", attributes: attr2))
        firstNameLbl.attributedText = firstNameStr
        
        let usernameStr = NSMutableAttributedString(attributedString: requireMark)
        usernameStr.append(NSAttributedString(string: "Username", attributes: attr2))
        usernameLbl.attributedText = usernameStr
        
        let passwordStr = NSMutableAttributedString(attributedString: requireMark)
        passwordStr.append(NSAttributedString(string: "Password", attributes: attr2))
        passwordLbl.attributedText = passwordStr
        
        let confirmStr = NSMutableAttributedString(attributedString: requireMark)
        confirmStr.append(NSAttributedString(string: "Confirm password", attributes:  attr2))
        confirmLbl.attributedText = confirmStr
        
    }
    
    @IBAction func createAccount(_ sender: Any) {
        guard let firstName = firstNameTxt.text,
              !firstName.isEmpty else {
            errorFirstNameLbl.alpha = 1
            return
        }
        errorFirstNameLbl.alpha = 0
        
        guard let lastName = lastNameTxt.text,
              !lastName.isEmpty else {
            errorLastNameLbl.alpha = 1
            return
        }
        errorLastNameLbl.alpha = 0
        
        guard let username = usernameTxt.text,
              !username.isEmpty else {
            errorUsernameLbl.text = "Username is required"
            errorUsernameLbl.alpha = 1
            return
        }
        errorUsernameLbl.alpha = 0
        
        guard let password = passwordTxt.text,
              !password.isEmpty else {
            errorPasswordLbl.text = "You must entered a password"
            errorPasswordLbl.alpha = 1
            return
        }
        errorPasswordLbl.alpha = 0
        
        guard let confirm = confirmTxt.text,
              confirm == password else {
            errorConfirmLbl.alpha = 1
            return
        }
        errorConfirmLbl.alpha = 0
        
        guard password.count >= 8 else {
            errorPasswordLbl.text = "Password is not secured"
            errorPasswordLbl.alpha = 1
            return
        }
        errorPasswordLbl.alpha = 0
        
        let link = serviceURL + "new_account.php"
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
                "password": password,
                "last_name": lastName,
                "first_name": firstName
            ]
            
            let jsondata = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsondata
        } catch {
            print("Error encoding data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard error == nil,
                  let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                print("Error: \(error!)")
                self.showAlert(title: "Connection Error", message: error!.localizedDescription)
                return
            }
            
            
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 409 {
                    DispatchQueue.main.async {
                        self.errorUsernameLbl.text = "The username is taken"
                        self.errorUsernameLbl.alpha = 1
                    }
                }
                print(String(data: data, encoding: .utf8) ?? "")
                return
            }
            
            print("Account created")
            print(String(data: data, encoding: .utf8) ?? "")
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Account Created.", message: nil, preferredStyle: .alert)
                let action = UIAlertAction(title: "OK", style: .default) {_ in
                    self.dismiss(animated: true)
                }
                
                alert.addAction(action)
                self.present(alert, animated: true)
            }
            
        }.resume()
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
