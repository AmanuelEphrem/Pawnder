//
//  AccountViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/8/21.
//

import UIKit

class AccountViewController: UIViewController {

    @IBOutlet weak var usernameLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //sets username label
        usernameLabel.text = "@"+PersonalData.username.lowercased()
    }
    
    @IBAction func mapPressed(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: false, completion: nil)
    }
    @IBAction func joinNeighborhoodBtn(_ sender: Any) {
    }
    
    @IBAction func logoutBtn(_ sender: Any) {
        self.presentingViewController?.presentingViewController?.dismiss(animated: false, completion: nil)
    }
}
