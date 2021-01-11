//
//  LoginViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/10/21.
//

import UIKit
import Firebase

class LoginViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    
    @IBAction func enterBtn(_ sender: Any) {
        retrievePersonalData(completion: {
            self.retrieveNeighborhoodData(completion: {
                self.performSegue(withIdentifier: "LoginToMap", sender: nil)
            })
        })
    }
    
    func retrievePersonalData(completion: @escaping () -> Void){
        let db = Firestore.firestore()
        let docRef = db.collection("users").document("bobby")
        
        //retrieves personal data
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()!
                //saves personal data
                PersonalData.username = dataDescription["username"]! as! String
                PersonalData.password = dataDescription["password"]! as! String
                PersonalData.neighborhoodID = dataDescription["neighborhoodID"]! as! Int
                PersonalData.personalPins = dataDescription["pins"] as! [Int]
                completion()
            } else {
                print("Document does not exist")
            }
        }
    }
    func retrieveNeighborhoodData(completion: @escaping () -> Void){
        let db = Firestore.firestore()
        let ref = db.collection("neighborhood").document("beverlyhills")

        //retrives neighborhood data
        ref.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()!
                
                //saves boundary information
                let boundarydata = dataDescription["boundaries"] as! [Double]
                var index = 0;
                var count = 0
                var vals = [LocationData]()
                while index < 4 {
                    vals.append(LocationData(latitude: boundarydata[count], longitude: boundarydata[(count+1)]))
                    count += 2
                    index += 1
                }
                NeighborhoodData.boundaries =  vals
                
                //saves neighborhood data
                NeighborhoodData.code = dataDescription["code"] as! Int
                NeighborhoodData.password = dataDescription["password"] as! String
                NeighborhoodData.description = dataDescription["description"] as! String
                NeighborhoodData.organizer = dataDescription["organizer"] as! String
                
                //returns completion
                completion()
            } else {
                print("Document does not exist")
            }
        }
    }
}
