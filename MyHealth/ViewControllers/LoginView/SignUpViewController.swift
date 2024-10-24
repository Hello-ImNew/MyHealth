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
    @IBOutlet weak var emailTxt: UITextField!
    @IBOutlet weak var errorLbl: UILabel!
    
    @IBOutlet weak var lastNameLbl: UILabel!
    @IBOutlet weak var firstNameLbl: UILabel!
    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var passwordLbl: UILabel!
    @IBOutlet weak var confirmLbl: UILabel!
    @IBOutlet weak var emailLbl: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        view.addGestureRecognizer(tapGesture)
        overrideUserInterfaceStyle = .light
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
        
        let emailStr = NSMutableAttributedString(attributedString: requireMark)
        emailStr.append(NSAttributedString(string: "Email", attributes:  attr2))
        emailLbl.attributedText = emailStr
        
        errorLbl.layer.cornerRadius = 10
        errorLbl.layer.borderWidth = 1
        errorLbl.layer.borderColor = UIColor.red.cgColor
        errorLbl.layer.masksToBounds = true
    }
    
    func getCredentials() -> [String: String]? {
        errorLbl.isHidden = true
        
        guard let firstName = firstNameTxt.text,
              !firstName.isEmpty else {
            errorLbl.text = "First name required"
            errorLbl.isHidden = false
            return nil
        }
        
        guard let lastName = lastNameTxt.text,
              !lastName.isEmpty else {
            errorLbl.text = "Last name required"
            errorLbl.isHidden = false
            return nil
        }
        
        guard let username = usernameTxt.text,
              !username.isEmpty else {
            errorLbl.text = "Username is required"
            errorLbl.isHidden = false
            return nil
        }
        
        guard let password = passwordTxt.text,
              !password.isEmpty else {
            errorLbl.text = "You must entered a password"
            errorLbl.isHidden = false
            return nil
        }
        
        guard let confirm = confirmTxt.text,
              confirm == password else {
            errorLbl.text = "Password do not match"
            errorLbl.isHidden = false
            return nil
        }
        
        guard let email = emailTxt.text,
              !email.isEmpty else {
            errorLbl.text = "Email is required"
            errorLbl.isHidden = false
            return nil
        }
        
        guard password.count >= 8 else {
            errorLbl.text = "Password is not secured"
            errorLbl.isHidden = false
            return nil
        }
        
        return ["username": username,
                "password": password,
                "first_name": firstName,
                "last_name": lastName,
                "email": email
        ]
        
    }
    
    @IBAction func createAccount(_ sender: Any) {
        guard let payload = getCredentials() else {
            return
        }
        let link = serviceURL + "check_username.php"
        guard let url = URL(string: link) else {
            print("Cannot connect to web service.")
            return
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let load = ["username": payload["username"]!,
                        "email": payload["email"]!]
            let jsondata = try JSONSerialization.data(withJSONObject: load)
            request.httpBody = jsondata
        } catch {
            print("Error encoding data: \(error)")
            return
        }
        
        ViewModels.sharedSession.dataTask(with: request) { (data, response, error) in
            guard error == nil,
                  let data = data,
                  let httpResponse = response as? HTTPURLResponse else {
                print("Error: \(error!)")
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 409 {
                    DispatchQueue.main.async {
                        self.errorLbl.text = String(data: data, encoding: .utf8)
                        self.errorLbl.isHidden = false
                    }
                }
                
                print(String(data: data, encoding: .utf8) ?? "")
                return
            }
            
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "EmailVerificationSegue", sender: self)
            }
        }.resume()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @objc func tappedOutside(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if (segue.identifier == "EmailVerificationSegue") {
            let destinationNav = segue.destination as? UINavigationController
            let destination = destinationNav?.topViewController as? CreateAccountVerificationViewController
            let load = getCredentials()!
            destination?.payload = load
        }
    }
    

}
