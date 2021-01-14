//
//  CreateAccountViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/13/21.
//

import UIKit

class CreateAccountViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
    }
    
    @IBAction func submitBtn(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
        
    }
    

}
