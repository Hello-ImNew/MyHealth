//
//  ForgotPasswordViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 6/11/24.
//

import UIKit

class ForgotPasswordViewController: UIViewController {

    @IBOutlet weak var usernameLbl: UILabel!
    @IBOutlet weak var errorUsernameLbl: UILabel!
    @IBOutlet weak var usernameTxt: UITextField!
    
    var username: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        view.addGestureRecognizer(tapGesture)
        overrideUserInterfaceStyle = .light
        //setUpLabel()
    }
    
    
    
//    func setUpLabel() {
//        let attr1 = [NSAttributedString.Key.foregroundColor: UIColor.red,
//                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
//        let attr2 = [NSAttributedString.Key.foregroundColor: UIColor.label,
//                     NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)]
//        let requiredMark = NSAttributedString(string: "*", attributes: attr1)
//
//        let usernameStr = NSMutableAttributedString(attributedString: requiredMark)
//        usernameStr.append(NSAttributedString(string: "Username", attributes: attr2))
//        usernameLbl.attributedText = usernameStr
//
//        let passwordStr = NSMutableAttributedString(attributedString: requiredMark)
//        passwordStr.append(NSAttributedString(string: "New password", attributes: attr2))
//        passwordLbl.attributedText = passwordStr
//
//        let confirmStr = NSMutableAttributedString(attributedString: requiredMark)
//        confirmStr.append(NSAttributedString(string: "Confirm password", attributes: attr2))
//        confirmLbl.attributedText = confirmStr
//    }
    
    @IBAction func forgotPassword(_ sender: Any) {
        guard let username = usernameTxt.text,
              !username.isEmpty else {
            errorUsernameLbl.text = "Username is required"
            errorUsernameLbl.alpha = 1
            return
        }
        errorUsernameLbl.alpha = 0
        self.username = username
        
        self.performSegue(withIdentifier: "ForgotPasswordVerificationSegue", sender: self)

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
        if segue.identifier == "ForgotPasswordVerificationSegue",
           let username = username {
            let verificationNav = segue.destination as? UINavigationController
            let verificationVC = verificationNav?.topViewController as? ForgotPasswordVerificationViewController
            verificationVC?.username = username
        }
    }
    

}
