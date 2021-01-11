//
//  AccountViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/8/21.
//

import UIKit

class AccountViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func mapPressed(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: false, completion: nil)
    }
    
}
