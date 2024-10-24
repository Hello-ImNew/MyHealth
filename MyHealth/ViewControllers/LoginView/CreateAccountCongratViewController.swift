//
//  CreateAccountCongratViewController.swift
//  MyHealth
//
//  Created by Bao Bui on 8/16/24.
//

import UIKit

class CreateAccountCongratViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tappedOutside(_:)))
        view.addGestureRecognizer(tapGesture)
        overrideUserInterfaceStyle = .light
        
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
