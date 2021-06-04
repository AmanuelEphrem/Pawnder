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
    //outlets from storyboard
    @IBOutlet weak var enterOutlet: UIButton!
    @IBOutlet weak var usernameTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    //checkmark outlets
    @IBOutlet weak var usernameX: UILabel!
    @IBOutlet weak var passwordX: UILabel!
    
    //user inputted username and password when submitBtn was fired
    private var user = ""
    private var pass = ""

    let btnLoading = LoadingButton(text: "Enter", textColor: .white, bgColor: UIColor(red: 247, green: 247, blue: 247, alpha: 0))
    
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
    
    //MARK: loading animation
    func startLoadAnimation(){
        btnLoading.alpha = 1
        enterOutlet.alpha = 0
    }
    func endLoadAnimation(){
        enterOutlet.alpha = 1
        btnLoading.alpha = 0
    }
    
    //MARK: UI Functions
    func usernameError(){
        UIView.animate(withDuration: 0.5) {
            self.usernameX.alpha = 1
        }
    }
    func passwordWrong(){
        UIView.animate(withDuration: 0.5) {
            self.passwordX.alpha = 1
        }
    }
    func resetTextfieldUI(){
        usernameX.alpha = 0
        passwordX.alpha = 0
    }
    func clearLoginScreenData(){
        usernameTextfield.text = ""
        passwordTextfield.text = ""
        user = ""
        pass = ""
    }
    @IBAction func createAccountBtn(_ sender: Any) {
        performSegue(withIdentifier: "LoginToCreateAccount", sender: nil)
    }
    //dismisses keyboard when screen is tapped
    @IBAction func viewTap(_ sender: Any) {
        view.endEditing(true)
    }
    


    //MARK: Login handling
    @IBAction func enterBtn(_ sender: Any) {
        //resets UI
        resetTextfieldUI()
        
        //reads textfield values
        user = usernameTextfield.text!.lowercased()
        pass = passwordTextfield.text!
        print(user)
        print(pass)
        //user = "bobby"
        //pass = "stevenwills980"

        //validates textfields (only validates username)
        if(databaseSafeString(str: user) == false){
            usernameError()
            return
        }
        
        //downloads user authentication (username and password) from Firebase
        //proceeds to home screen if authentication is correct
        downloadPersonalData(completion: { isAuthorized in
            if(isAuthorized == true){
                self.startLoadAnimation()
                
                self.downloadNeighborhoodData(completion: { success in
                    self.endLoadAnimation()
                    
                    if(success == false){
                        print("Not part of a neighborhood...yet")
                        return
                    }
                    self.performSegue(withIdentifier: "LoginToMap", sender: nil)
                    self.clearLoginScreenData()
                })
            }
        })
    }
    private func downloadPersonalData(completion: @escaping (Bool) -> Void){
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(user)
        
        //retrieves personal data
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let dataDescription = document.data()!
                
                //validates login information (username already checked)
                let expectedPassword = dataDescription["password"]! as! String
                if(self.pass != expectedPassword){
                    //wrong password
                    self.passwordWrong()
                    completion(false)
                    return
                }
                //saves personal data
                PersonalData.username = dataDescription["username"]! as! String
                PersonalData.password = expectedPassword
                PersonalData.neighborhoodID = dataDescription["neighborhoodID"]! as! String
                PersonalData.personalPins = dataDescription["pins"] as! [String]

                completion(true)
            } else {
                //username is wrong
                self.usernameError()
                completion(false)
            }
        }
    }
    private func downloadNeighborhoodData(completion: @escaping (Bool) -> Void){
        //quits if there's no neighborhood
        if(PersonalData.neighborhoodID == ""){
            completion(false)
            return
        }
        
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
                NeighborhoodData.name = PersonalData.neighborhoodID
                NeighborhoodData.code = dataDescription["code"] as! Int
                NeighborhoodData.password = dataDescription["password"] as! String
                NeighborhoodData.description = dataDescription["description"] as! String
                NeighborhoodData.organizer = dataDescription["organizer"] as! String
                
                //returns completion
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    private func databaseSafeString(str:String) -> Bool{
        //makes sure username has contents
        if(str == ""){
            return false
        }
        
        //loops username for each characte
        let pattern = "[0-9]|[a-z]"
        for letter in str{
            if(matches(str:String(letter), pattern) == false){
                return false
            }
        }
        return true
    }
    //databaseSafeString helper function
    private func matches(str:String,_ regex: String) -> Bool {
        return str.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }

}
