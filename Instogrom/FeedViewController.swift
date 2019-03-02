//
//  FeedViewController.swift
//  Instogrom
//
//  Created by Michael Cheng on 18/05/2017.
//  Copyright © 2017 Michael Cheng. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseDatabaseUI
import SDWebImage
import Firebase
import FirebaseAuth
import FirebaseStorage
import SVProgressHUD



class FeedViewController: UITableViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate{

    
    
    var ref: FIRDatabaseReference!
    var dataSource: FUITableViewDataSource!
    var isFirstLoad = true
    var queryRef: FIRDatabaseQuery!
    var toDeleteRef: FIRDatabaseReference!
    


    
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
    
    
    
    @IBAction func logOutTapped(_ sender: Any) {
        try! FIRAuth.auth()?.signOut()
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
        let postRef = ref.childByAutoId()
        let imagePath = "photos/\(postRef.key).jpg"
        
        let storageRef = FIRStorage.storage().reference()
        //use the key of the ID as the name for the photo
        let imageRef = storageRef.child(imagePath)
        
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = imageRef.put(imageData, metadata: metadata) { metadata, error in
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
                "postDateReversed": -nowMS,
                "comment": ""
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
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = UITableViewAutomaticDimension
        //giving an estimate would speed up the view controller
        tableView.estimatedRowHeight = 425
        
        if isFirstLoad, FIRAuth.auth()?.currentUser != nil{
            DispatchQueue.main.async {
                SVProgressHUD.show()
            }
        }
        
        ref = FIRDatabase.database().reference().child("posts")
        queryRef = ref.queryOrdered(byChild: "postDateReversed")
        //debugPrint(queryRef)
        
        //show data from old to new
        //dataSource = tableView.bind(to: ref) { (tableView, indexPath, snapshot) -> UITableViewCell in
        
        //show data from new to old
        dataSource = tableView.bind(to: queryRef, populateCell: { (tableView, indexPath, snapshot) -> UITableViewCell in
  
            let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostCell
            //print("printing snapshot")
            //debugPrint (snapshot.value)
            
            //http://stackoverflow.com/questions/28058082/swift-long-press-gesture-recognizer-detect-taps-and-long-press
            let tapGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.imageLongPressed(tapGestureRecognizer:)))
            cell.photoImageView.isUserInteractionEnabled = true
            cell.photoImageView.addGestureRecognizer(tapGestureRecognizer)
            
            
            
            let postData = snapshot.value as! [String: Any]
            cell.emailLabel.text = postData["email"] as? String
            let imageURL = URL(string: postData["imageURL"] as! String)
            cell.photoImageView.sd_setImage(with: imageURL)
            cell.cellPostRef = snapshot.ref
            let comment = postData["comment"] as? String
            if comment != "" {
                cell.commentLabel.isHidden = false
                cell.commentLabel.text = comment
                //debugPrint (comment)
            }
            
            
            //debugPrint(cell.referenceLabel.text)
            
            
            if self.isFirstLoad {
                self.isFirstLoad = false
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                }
            }

            return cell
        })
    }
    
    
    
    func imageLongPressed(tapGestureRecognizer: UILongPressGestureRecognizer){
        
        let pressedImage = (tapGestureRecognizer.view as! UIImageView).image!
        print("photo long pressed")
        
        let shareActionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let commentActionSheet = UIAlertController(title: "Comment", message: nil, preferredStyle: .alert)

        let deleteButton = UIAlertAction(title: "Delete image", style: .destructive) { action -> Void in

//            use superview to retrieve the cell of the image tapped
//            http://stackoverflow.com/questions/28659845/swift-how-to-get-the-indexpath-row-when-a-button-in-a-cell-is-tapped
            let superView = tapGestureRecognizer.view?.superview
            //debugPrint(superView?.superview?.superview)
            if let cell = superView?.superview?.superview as? PostCell{
                cell.cellPostRef.removeValue()
            }
            
//            retrieve the row number at which the cell which was tapped
//            http://stackoverflow.com/questions/29360673/getting-uitableviewcell-from-uitapgesturerecognizer
//            let touch = tapGestureRecognizer.location(in: self.tableView)
//            if let indexPath = self.tableView.indexPathForRow(at: touch){
//                let rowNum = (indexPath.row + 1) as IndexPath
//            } else {
//                let rowNum = 0 as IndexPath
//            }
//            let toDeleteCell = tableView.cellForRow(at: rowNum)
        }
        

        
        
        //http://stackoverflow.com/questions/38416182/swift3-add-button-with-code
        let copyLinkButton = UIAlertAction(title: "Copy image", style: .default) { action -> Void in
//            print("copy")
            //http://stackoverflow.com/questions/24670290/how-to-copy-text-to-clipboard-pasteboard-with-swift
            UIPasteboard.general.image = pressedImage
        }
        
        let shareInLineButton = UIAlertAction(title: "Share via Line", style: .default, handler: { (action) -> Void in
//            print("line")
            
            let pasteBoard = UIPasteboard.general
            pasteBoard.image = pressedImage
            //pasteBoard.setData(UIImageJPEGRepresentation(pressedImage, 1)!, forPasteboardType: "lineImage")
            //debugPrint (pasteBoard.name.rawValue)
            //https://cg2010studio.com/2014/04/24/ios-%E4%BD%BF%E7%94%A8line%E5%88%86%E4%BA%AB/
            UIApplication.shared.openURL(URL(string: ("line://msg/image/" + pasteBoard.name.rawValue))!)
        })
        
        let commentButton = UIAlertAction(title: "Comment", style: .default) { (action) in
            //http://stackoverflow.com/questions/24093612/how-to-add-a-textfield-to-uialertview-in-swift
            commentActionSheet.addTextField(configurationHandler: { (textField) in
                textField.placeholder = "Comment"
                textField.keyboardType = .default
            })
            let cancelCommentButton = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel) { (result : UIAlertAction) -> Void in
            }
            commentActionSheet.addAction(cancelCommentButton)
            let okCommentButton = UIAlertAction(title: "OK", style: UIAlertActionStyle.default) { (result : UIAlertAction) -> Void in
                //access the text field in hanlder of okay action
                //http://stackoverflow.com/questions/26567413/get-input-value-from-textfield-in-ios-alert-in-swift
                let textField = commentActionSheet.textFields![0]
                let superView = tapGestureRecognizer.view?.superview
                //debugPrint(superView?.superview?.superview)
                if let cell = superView?.superview?.superview as? PostCell{
                    cell.cellPostRef.updateChildValues([
                        "comment": cell.commentLabel.text! + textField.text! + "\n"
                    ])
                }
            }
            commentActionSheet.addAction(okCommentButton)
            self.present(commentActionSheet, animated: true, completion: nil)
            
        }
        
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) -> Void in
            print("cancel")
        })
        
        shareActionSheet.addAction(copyLinkButton)
        shareActionSheet.addAction(shareInLineButton)
        shareActionSheet.addAction(commentButton)
        shareActionSheet.addAction(deleteButton)
        shareActionSheet.addAction(cancelButton)
        //present actionsheet when there isnt one
        //http://stackoverflow.com/questions/28270282/what-is-the-best-way-to-check-if-a-uialertcontroller-is-already-presenting
        if self.presentedViewController == nil {
            // UIAlertController is presenting.Here
             present(shareActionSheet, animated: true, completion: nil)
        }
       

    }


}
