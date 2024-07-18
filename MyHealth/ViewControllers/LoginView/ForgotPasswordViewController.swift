//
//  ForgotPasswordViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 6/11/24.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var passwordLbl: UILabel!
    @IBOutlet weak var confirmLbl: UILabel!
    @IBOutlet weak var errorUsernameLbl: UILabel!
    @IBOutlet weak var errorPasswordLbl: UILabel!
    @IBOutlet weak var errorConfirmLbl: UILabel!
    @IBOutlet weak var usernameTxt: UITextField!
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var confirmTxt: UITextField!
    
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
        let requiredMark = NSAttributedString(string: "*", attributes: attr1)
        
        let usernameStr = NSMutableAttributedString(attributedString: requiredMark)
        usernameStr.append(NSAttributedString(string: "Username", attributes: attr2))
        usernameLbl.attributedText = usernameStr
        
        let passwordStr = NSMutableAttributedString(attributedString: requiredMark)
        passwordStr.append(NSAttributedString(string: "New password", attributes: attr2))
        passwordLbl.attributedText = passwordStr
        
        let confirmStr = NSMutableAttributedString(attributedString: requiredMark)
        confirmStr.append(NSAttributedString(string: "Confirm password", attributes: attr2))
        confirmLbl.attributedText = confirmStr
    }
    
    @IBAction func forgotPassword(_ sender: Any) {
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
        
        let link = serviceURL + "forgot_password.php"
        guard let url = URL(string: link) else {
            print("Cannot connect to web service.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            let payload = [
                "username": username,
                "new_password": password
            ]
            let jsondata = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsondata
        } catch {
            print("Error encoding data: \(error)")
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  error == nil else {
                print("Error: \(error!)")
                self.showAlert(title: "Connection Error", message: error!.localizedDescription)
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 409 {
                    DispatchQueue.main.async {
                        self.errorUsernameLbl.text = "Username not found"
                        self.errorUsernameLbl.alpha = 1
                    }
                }
                
                print(String(data: data, encoding: .utf8) ?? "")
                return
            }
            
            print("Password Changed")
            print(String(data: data, encoding: .utf8) ?? "")
            DispatchQueue.main.async {
                self.dismiss(animated: true)
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
