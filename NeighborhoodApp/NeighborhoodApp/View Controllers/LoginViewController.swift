//
//  LoginViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/10/21.
//

import UIKit
import Foundation
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
    ///check mark outlets
    @IBOutlet weak var usernameCheck: UIImageView!
    @IBOutlet weak var passwordCheck: UIImageView!
    @IBOutlet weak var usernameX: UILabel!
    @IBOutlet weak var passwordX: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //creates loading button
        btnLoading.frame = CGRect(x: 78, y: 411, width: 40, height: 40)
        btnLoading.indicator = MaterialLoadingIndicator(color: .blue)
        btnLoading.isUserInteractionEnabled = false
        btnLoading.showLoader(userInteraction: true)
        btnLoading.alpha = 0
        self.view.addSubview(btnLoading)
        
        //sets UI
        resetTextfieldUI()
        
        //delegates
        usernameTextfield.delegate = self
        passwordTextfield.delegate = self
        
        }
    
    //dismisses keyboard when screen is tapped
    @IBAction func viewTap(_ sender: Any) {
        view.endEditing(true)
    }
    
    //animation for loading screen
    func startLoadAnimation(){
        btnLoading.alpha = 1
        enterOutlet.alpha = 0
    }
    func endLoadAnimation(){
        enterOutlet.alpha = 1
        btnLoading.alpha = 0
    }
    
    //displaying correct UI for textfields
    func usernameError(){
        usernameCheck.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.usernameX.alpha = 1
        }
    }
    func passwordWrong(){
        passwordCheck.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.passwordX.alpha = 1
        }
    }
    func resetTextfieldUI(){
        usernameCheck.alpha = 0
        passwordCheck.alpha = 0
        usernameX.alpha = 0
        passwordX.alpha = 0
    }
    
    //enterBtn helper function
    private func validateUsernameInput(username:String) -> Bool{
        //makes sure username has contents
        if(username == ""){
            return false
        }
        
        //loops username for each characte
        let pattern = "[0-9]|[a-z]"
        for letter in username{
            if(matches(str:String(letter), pattern) == false){
                return false
            }
        }
        return true
    }
    
    //validateUsernameInput helper function
    private func matches(str:String,_ regex: String) -> Bool {
        return str.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
    
    @IBAction func enterBtn(_ sender: Any) {
        //resets UI
        resetTextfieldUI()
        ///
        ///
        ///
        ///edited here
        ///
        ///
        ///
        //reads textfield values
        //user = usernameTextfield.text!.lowercased() ///uncomment
        //pass = passwordTextfield.text!  ///uncomment
        user = "bobby"
        pass = "stevenwills980"
        
        //validates username accordance with firebase criterion
        if(validateUsernameInput(username: user) == false){
            usernameError()
            return
        }
        
        //checks if login is correct
        //user is granted access if and only if login is correct
        retrievePersonalData(completion: {
            if(self.isAuthorized){
                //starts animation if access is granted
                self.startLoadAnimation()
                self.retrieveNeighborhoodData(completion: {
                    self.retrievePinData {
                        self.performSegue(withIdentifier: "LoginToMap", sender: nil)
                        self.endLoadAnimation()
                    }
                })
            }
        })
    }
    
    //downloads user data
    //if user credentials are correct, data is saved and authorized to enter
    //else the user is not authorized and data is not saved
    func retrievePersonalData(completion: @escaping () -> Void){
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user)
        
        //retrieves personal data
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()!
                
                //checks login
                let tempPassword = dataDescription["password"]! as! String
                if(self.pass != tempPassword){
                    //wrong password
                    self.passwordWrong()
                    completion()
                    return
                }
                //saves personal data
                PersonalData.username = dataDescription["username"]! as! String
                PersonalData.password = tempPassword
                PersonalData.neighborhoodID = dataDescription["neighborhoodID"]! as! String
                PersonalData.personalPins = dataDescription["pins"] as! [Int]
                
                //validates user
                self.isAuthorized = true
                completion()
            } else {
                //denies access if username wrong
                self.usernameError()
                self.isAuthorized = false
                completion()
            }
        }
    }
    func retrieveNeighborhoodData(completion: @escaping () -> Void){
        let db = Firestore.firestore()
        let ref = db.collection("neighborhood").document(PersonalData.neighborhoodID)

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
        var id = ""
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
                    id = info["ID"] as! String
                    location = info["location"] as! [Double]
                    pins.append(PinData(title: title, description: description, ID: id, locaiton: LocationData(latitude: location[0], longitude: location[1])))
                }
                print("number of saved pins \(pins.count)")
                NeighborhoodData.pins = pins
                completion()
            }
        }

    }
    
    @IBAction func createAccountBtn(_ sender: Any) {
        performSegue(withIdentifier: "LoginToCreateAccount", sender: nil)
    }
    
}
