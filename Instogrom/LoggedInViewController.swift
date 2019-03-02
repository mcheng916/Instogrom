//
//  LoggedInViewController.swift
//  Instogrom
//
//  Created by Michael Cheng on 08/05/2017.
//  Copyright © 2017 Michael Cheng. All rights reserved.
//

import Firebase
import FirebaseAuth
import FirebaseStorage
import UIKit
import FirebaseDatabase

class LoggedInViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

    @IBOutlet weak var imageView: UIImageView!
    var postsReference: FIRDatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        postsReference = FIRDatabase.database().reference().child("posts")
//        ref.observe(.value) { snapshot in
//            debugPrint(snapshot.value)
//        }
        
        postsReference.observe(.childAdded) { snapshot in
            debugPrint(snapshot.value!)
        }
        
        //All data in the database will be changed to only "hello"
        //ref.setValue("hello")
        
        //The following will only add data in the database
//        ref.updateChildValues([
//            "Hello": "world",
//            "Hola": "amigo",
//            "Apple": "pen"
//            ])
        
        //update child values
//        let postRef = postsReference.childByAutoId()
//        postRef.updateChildValues([
//                "Hello": "world",
//                "Hola": "amigo",
//            ])

        //Remove all values in the reference
//        ref.removeValue()
    }
    
    
    
    @IBAction func logOutTapped(_ sender: Any) {
        try! FIRAuth.auth()?.signOut()
    }
    
    @IBAction func addPhotoTapped(_ sender: Any) {
        let picker = UIImagePickerController()
        //picker would inform the view controller if anything happens
        picker.delegate = self
        
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let takePictureAction = UIAlertAction(title: "Take picture", style: .default) { action in
                print("Take pictures")
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    picker.sourceType = .camera
                    self.present(picker, animated: true, completion: nil)
                }
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
        print("User has finished picking photos")
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        guard let imageData = UIImageJPEGRepresentation(image, 0.5) else {
            print("Cant convert the photo to jpeg")
            return
        }
        
        //generate ID for the post here
        let postRef = postsReference.childByAutoId()
        let imagePath = "photos/\(postRef.key).jpg"
        
        let storageRef = FIRStorage.storage().reference()
        //use the key of the ID as the name for the photo
        let imageRef = storageRef.child(imagePath)
        
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.put(imageData, metadata: metadata) { metadata, error in
            guard let metadata = metadata else {
                print ("upload failure")
                return
            }
            print ("upload has started")
            debugPrint(metadata.downloadURL()!)
            
            //store in realtime database after URL is generated
            //how to get UID since we are not in authentication addStateDidChangeListener
            
            let currentUser = (FIRAuth.auth()?.currentUser)!
            guard let downloadURL = metadata.downloadURL() else{
                print("failed to acquire download URL")
                return
            }
            
            let now = Date()
            let nowMS = now.timeIntervalSince1970 * 1000
            postRef.updateChildValues([
                "authorUID": currentUser.uid,
                "email": currentUser.email!,
                "imagePath": imagePath,
                "imageURL": downloadURL.absoluteString,
                "postDate": nowMS,
                ])
        }
        
        self.imageView.image = image
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print ("user has canceled picking photos")
        dismiss(animated: true, completion: nil)
    }
    
    
}
