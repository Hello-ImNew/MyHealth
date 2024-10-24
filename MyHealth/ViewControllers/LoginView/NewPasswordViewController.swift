//
//  NewPasswordViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 8/13/24.
//

import UIKit

class NewPasswordViewController: UIViewController {
    
    @IBOutlet weak var passwordTxt: UITextField!
    @IBOutlet weak var confirmTxt: UITextField!
    @IBOutlet weak var errorPasswordLbl: UILabel!
    @IBOutlet weak var errorConfirmLbl: UILabel!
    
    var username: String!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        view.addGestureRecognizer(tapGesture)
        overrideUserInterfaceStyle = .light
    }
    
    func showResetSuccess() {
        let alertController = UIAlertController(title: "Reset Password Success",
                                                message: "You have successfully reset your password",
                                                preferredStyle: .alert)
        let toLogin = UIAlertAction(title: "Continue to sign in", style: .default, handler: { action in
            guard let window = self.view.window else {
                return
            }
            
            let transition = CATransition()
            transition.type = .push
            transition.subtype = .fromRight
            transition.duration = 0.3
            window.layer.add(transition, forKey: kCATransition)
            
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let loginViewController = mainStoryboard.instantiateViewController(withIdentifier: "LogInView")
            window.rootViewController = loginViewController
            window.makeKeyAndVisible()
            return
        })
        
        alertController.addAction(toLogin)
        DispatchQueue.main.async {
            self.present(alertController, animated: true)
        }
    }
    
    @IBAction func confirmTapped(_ sender: UIButton) {
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
            return
        }

        ViewModels.sharedSession.dataTask(with: request) { (data, response, error) in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  error == nil else {
                print("Error: \(error!)")
                self.showAlert(title: "Connection Error", message: error!.localizedDescription)
                return
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                print(String(data: data, encoding: .utf8) ?? "")
                return
            }

            print("Password Changed")
            print(String(data: data, encoding: .utf8) ?? "")
            self.showResetSuccess()
        }.resume()
    }
    
    @objc func tappedOutside(_ gesture: UITapGestureRecognizer) {
        view.endEditing(true)
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
