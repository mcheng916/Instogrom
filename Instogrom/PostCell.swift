//
//  PostCell.swift
//  Instogrom
//
//  Created by Michael Cheng on 18/05/2017.
//  Copyright © 2017 Michael Cheng. All rights reserved.
//

import UIKit
import FirebaseDatabase

class PostCell: UITableViewCell {

    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var commentLabel: UILabel!
    var cellPostRef: FIRDatabaseReference!
}
