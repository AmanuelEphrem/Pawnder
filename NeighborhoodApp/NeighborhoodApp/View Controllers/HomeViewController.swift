//
//  HomeViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/8/21.
//

import UIKit

class HomeViewController: UIViewController {
    
  
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func locationPressed(_ sender: Any) {
    }
    
    //shows user account screen
    @IBAction func accountPressed(_ sender: Any) {
        performSegue(withIdentifier: "MapToAccount", sender: nil)
    }
    
    @IBAction func mapPressed(_ sender: Any) {
    }
    
}
