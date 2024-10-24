//
//  CreateAccountVerificationViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 8/6/24.
//

import UIKit

class CreateAccountVerificationViewController: UIViewController {
    
    @IBOutlet weak var codeTxt: UITextField!
    @IBOutlet weak var verifyLbl: UILabel!
    
    var payload: [String: String]!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        view.addGestureRecognizer(tapGesture)
        
        overrideUserInterfaceStyle = .light
        sendVerificationCode()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        verifyLbl.text = "Please enter 6-digits code sent to:\n" + (payload["email"] ?? "")
    }
    
    func sendVerificationCode() {
        let link = serviceURL + "create_account_verification.php"
        guard let url = URL(string: link) else {
            print("Cannot connect to web service.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let payload = ["email": payload["email"]!]
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
                print("Failed to send code")
                print(String(data: data, encoding: .utf8)!)
                return
            }
            
            print("Code Created")
        }.resume()
    }
    
    
    @IBAction func verifyEmail(_ sender: Any) {
        guard let code = codeTxt.text,
              code.count == 6 else {
            return
        }
        
        let link = serviceURL + "new_account.php"
        guard let url = URL(string: link)else {
            print("Cannot connect to web service.")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            payload["code"] = code
            let jsondata = try JSONSerialization.data(withJSONObject: payload)
            request.httpBody = jsondata
        } catch {
            print("Error encoding data: \(error)")
            return
        }
        
        ViewModels.sharedSession.dataTask(with: request) {(data, response, error) in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  error == nil else {
                print("Error: \(error!)")
                self.showAlert(title: "Connection Error", message: error!.localizedDescription)
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                if httpResponse.statusCode == 401 {
                    self.showAlert(title: "Incorrect Code", message: "The code was incorrect or has expired.")
                } else {
                    self.showAlert(title: "Server Error", message: String(data: data, encoding: .utf8)!)
                }
                return
            }
            
            DispatchQueue.main.async {
                self.performSegue(withIdentifier: "CongratNewAccountSegue", sender: self)
            }
        }.resume()
    }
    
    @IBAction func toSignIn(_ sender: Any) {
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
    }
    
    @IBAction func resendCode(_ sender: UIButton) {
        sendVerificationCode()
        
        var countDown = 5
        sender.isEnabled = false
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { timer in
            sender.setTitle("Resend Code(\(countDown))", for: .normal)
            countDown -= 1
            if countDown < 0 {
                timer.invalidate()
                
                sender.setTitle("Resend Code", for: .normal)
                sender.isEnabled = true
            }
        })
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        self.dismiss(animated: true)
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
