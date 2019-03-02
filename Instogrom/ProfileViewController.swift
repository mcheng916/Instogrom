//
//  ProfileViewController.swift
//  Instogrom
//
//  Created by Michael Cheng on 21/05/2017.
//  Copyright © 2017 Michael Cheng. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import SVProgressHUD

import FirebaseDatabaseUI
import SDWebImage
import Firebase


class ProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    

    @IBOutlet weak var profilePhotoView: UIImageView!
    @IBOutlet weak var emailLabel: UILabel!

    override func viewDidLoad() {

        super.viewDidLoad()
        
        guard let user = FIRAuth.auth()?.currentUser else{
            return
        }
        let userID = user.uid
        emailLabel.text = user.email!
        
        
        let ref = FIRDatabase.database().reference().child("users").child(userID)
        ref.observe(FIRDataEventType.value, with: { (snapshot) in
            let userPhotoData = snapshot.value as! [String: Any]
            let imageURL = URL(string: userPhotoData["photo"] as! String)
            self.profilePhotoView.sd_setImage(with: imageURL)
        })
    }
    
    @IBAction func addProfilePhotoTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        //picker would inform the view controller if anything happens
        picker.delegate = self
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let takePictureAction = UIAlertAction(title: "Take picture", style: .default) { action in
                print("Take pictures")
                picker.sourceType = .camera
                self.present(picker, animated: true, completion: nil)
                
            }
            actionSheet.addAction(takePictureAction)
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary){
            let choosePictureAction = UIAlertAction(title: "Choose picture", style: .default) { action in
                print("Choose pictures")
                picker.sourceType = .photoLibrary
                self.present(picker, animated: true, completion: nil)
            }
            actionSheet.addAction(choosePictureAction)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        actionSheet.addAction(cancelAction)
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    
    
    //info contains the original image and the edited image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            print("Cant convert the photo to jpeg")
            return
        }
        
        let currentUser = (FIRAuth.auth()?.currentUser)!
        let userUID = currentUser.uid
        //generate ID for the post here

        let imagePath = "photos/" + userUID + ".jpg"
        //debugPrint(imagePath)
        //print("idk about this one")
        let storageRef = FIRStorage.storage().reference()

        //use the key of the ID as the name for the photo
        let imageRef = storageRef.child(imagePath)
        let profileRef = FIRDatabase.database().reference().child("users").child(userUID)
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = imageRef.put(imageData, metadata: metadata) { metadata, error in
            guard let metadata = metadata else {
                print ("upload failure")
                return
            }
            print ("upload has started")
            //debugPrint(metadata.downloadURL()!)
            
            //store in realtime database after URL is generated
            //how to get UID since we are not in authentication addStateDidChangeListener
            

            guard let downloadURL = metadata.downloadURL() else{
                print("failed to acquire download URL")
                return
            }
            
            profileRef.updateChildValues([
                "photo": downloadURL.absoluteString
                ])
        }
        
        
        
        // Add a progress observer to an upload task
        uploadTask.observe(.progress) { snapshot in
            // A progress event occured
            let percentComplete = 100.0 * Float(snapshot.progress!.completedUnitCount)
                / Float(snapshot.progress!.totalUnitCount)
            debugPrint(percentComplete)
            DispatchQueue.main.async {
                SVProgressHUD.showProgress(percentComplete)
                //print("show progress")
            }
        }
        
        uploadTask.observe(.success) { snapshot in
            // Upload completed successfully
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                //print("dismiss UIIMagePcikerController")
            }
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print ("user has canceled picking photos")
        dismiss(animated: true, completion: nil)
    }
    

    
    @IBAction func signOutTapped(_ sender: Any) {
        try? FIRAuth.auth()?.signOut()
    }
}
