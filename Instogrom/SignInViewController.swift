//
//  SignInViewController.swift
//  Instogrom
//
//  Created by Michael Cheng on 07/05/2017.
//  Copyright © 2017 Michael Cheng. All rights reserved.
//

import UIKit
import FirebaseAuth

class SignInViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBAction func signInTapped(_ sender: Any) {
        guard let email = emailField.text, let password = passwordField.text else{
            print("email or password wasnt entered")
            return
        }
        FIRAuth.auth()?.signIn(withEmail: email, password: password) { user, error in
            guard let user = user else{
                print("sign in error")
                if let error = error {
                    debugPrint(error)
                }
                return
            }
            print("sign in successful!")
            debugPrint(user.email!, user.uid)
        }
    }
    

}
    

