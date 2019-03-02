//
//  SignUpViewController.swift
//  Instogrom
//
//  Created by Michael Cheng on 07/05/2017.
//  Copyright © 2017 Michael Cheng. All rights reserved.
//

import UIKit
import Firebase
import FirebaseAuth

class SignUpViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!

    @IBAction func signUpTapped(_ sender: Any) {
        guard let email = emailField.text, let password = passwordField.text, let confirmPassword = confirmPasswordField.text  else{
            print("email or password wasnt entered")
            return
        }
        //First check if both password entered are the same
        if password != confirmPassword {
            print("passwords entered arent the same")
            return
        }
        FIRAuth.auth()?.createUser(withEmail: email, password: password) { user, error in
            guard let user = user else{
                print("registration error")
                if let error = error {
                    debugPrint(error)
                }
                return
            }
            print("registration successful!")
            debugPrint(user.uid)
            
        }
    }
    @IBAction func backToSignInTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}
