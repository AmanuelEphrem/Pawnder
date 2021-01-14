//
//  LoginViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/10/21.
//

import UIKit
import Firebase
import MHLoadingButton

class LoginViewController: UIViewController, UITextFieldDelegate{
    //instance data that represents user inputted values
    private var user = ""
    private var pass = ""
    //instance data that represents whether user login is validated
    private var isAuthorized = false
    
    let btnLoading = LoadingButton(text: "Enter", textColor: .white, bgColor: UIColor(red: 247, green: 247, blue: 247, alpha: 0))
   
    //outlets from storyboard
    @IBOutlet weak var enterOutlet: UIButton!
    @IBOutlet weak var usernameTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //creates loading button
        btnLoading.frame = CGRect(x: 78, y: 411, width: 40, height: 40)
        btnLoading.indicator = MaterialLoadingIndicator(color: .black)
        btnLoading.isUserInteractionEnabled = false
        btnLoading.showLoader(userInteraction: true)
        btnLoading.alpha = 0
        self.view.addSubview(btnLoading)
        
        //delegates
        usernameTextfield.delegate = self
        passwordTextfield.delegate = self
        
        }
    
    @IBAction func viewTap(_ sender: Any) {
        view.endEditing(true)
        
    }
    
    
    func startAnimation(){
        btnLoading.alpha = 1
        enterOutlet.alpha = 0
    }
    func endAnimation(){
        enterOutlet.alpha = 1
        btnLoading.alpha = 0
    }
    
    
    @IBAction func enterBtn(_ sender: Any) {
        

        //reads textfield values
        user = usernameTextfield.text!
        pass = passwordTextfield.text!
        
        //checks if login is correct
        //user is granted access if and only if login is correct
        retrievePersonalData(completion: {
            print(self.isAuthorized)
            if(self.isAuthorized){
                //starts animation if access is granted
                self.startAnimation()
                self.retrieveNeighborhoodData(completion: {
                    self.retrievePinData {
                        self.performSegue(withIdentifier: "LoginToMap", sender: nil)
                        self.endAnimation()
                    }
                })
            }
        })
    }
    
    //downloads user data
    //if user credentials are correct, data is saved and authorized to enter
    //else the user is not authorized and data is not saved
    func retrievePersonalData(completion: @escaping () -> Void){
        
        let seconds = 100.0
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            // Put your code which should be executed with a delay here
        }
        
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user)
        
        //retrieves personal data
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()!
                
                //checks login
                let tempPassword = dataDescription["password"]! as! String
                if(self.pass != tempPassword){
                    completion()
                    return
                }
                //saves personal data
                PersonalData.username = dataDescription["username"]! as! String
                PersonalData.password = tempPassword
                PersonalData.neighborhoodID = dataDescription["neighborhoodID"]! as! Int
                PersonalData.personalPins = dataDescription["pins"] as! [Int]
                
                //validates user
                self.isAuthorized = true
                completion()
            } else {
                //denies access if document is not found
                self.isAuthorized = false
                completion()
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
    
    func retrievePinData(completion: @escaping () -> Void){
        let db = Firestore.firestore()
        let ref = db.collection("neighborhood").document("beverlyhills").collection("pins")
        var pins = [PinData]()
        var title = ""
        var description = ""
        var location = [Double]()
        
        ref.getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion()
            } else {
                for document in querySnapshot!.documents {
                    let info = document.data()
                    title = info["title"] as! String
                    description = info["description"] as! String
                    location = info["location"] as! [Double]
                    pins.append(PinData(title: title, description: description, locaiton: LocationData(latitude: location[0], longitude: location[1])))
                }
                NeighborhoodData.pins = pins
                completion()
            }
        }

    }
    
    @IBAction func createAccountBtn(_ sender: Any) {
        performSegue(withIdentifier: "LoginToCreateAccount", sender: nil)
    }
    
}
