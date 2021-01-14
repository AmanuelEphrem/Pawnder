//
//  CreateAccountViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/13/21.
//

import UIKit
import Firebase
import MHLoadingButton
class CreateAccountViewController: UIViewController {
    
    //outlet variables
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameX: UILabel!
    @IBOutlet weak var passwordX: UILabel!
    @IBOutlet weak var submitOutlet: UIButton!
    
    //instance data
    private var success = false
    let btnLoading = LoadingButton(text: "Enter", textColor: .white, bgColor: UIColor(red: 247, green: 247, blue: 247, alpha: 0))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //setup loading button
        //creates loading button
        btnLoading.frame = CGRect(x: 78, y: 411, width: 40, height: 40)
        btnLoading.indicator = MaterialLoadingIndicator(color: .blue)
        btnLoading.isUserInteractionEnabled = false
        btnLoading.showLoader(userInteraction: true)
        btnLoading.alpha = 0
        self.view.addSubview(btnLoading)
        
        //setup Error UI
        resetErrors()

        
    }
    
    @IBAction func submitBtn(_ sender: Any) {
        //clears visual errors
        resetErrors()
        
        //attempts to writes to database
        sendUserInfo(completion: {
            //ends loading animation because writing has ended
            self.endLoadingAnimation()
            //exits view if write is successful
            if(self.success == true){
                self.presentingViewController?.dismiss(animated: true, completion: nil)
            }
        })
        
    }
    
    func sendUserInfo(completion: @escaping () -> Void){
        let username = usernameTextField.text!.lowercased()
        let password = passwordTextField.text!
        let neighborhoodID = -1
        let pins:[Int] = [-1,-1,-1]
        
        if(validateUserInput(username: username) == false){
            //username error
            usernameError()
            success = false
            completion()
            return
        }else if(password == ""){
            //password error
            passwordError()
            success = false
            completion()
            return
        }
        
        //begins loading animation because data is being written
        startLoadingAnimation()
        
        //writes data
        let db = Firestore.firestore()
        db.collection("users").document(username).setData([
            "username": username,
            "password": password,
            "neighborhoodID": neighborhoodID,
            "pins":pins
        ]) { err in
            if let err = err {
                //error writing data
                self.success = false
                self.usernameError()
                completion()
            } else {
                //success writing
                self.success = true
                completion()
            }
        }
        
        
    }
    
    //starts loading animation
    func startLoadingAnimation(){
        btnLoading.alpha = 1
        submitOutlet.alpha = 0
    }
    
    func endLoadingAnimation(){
        btnLoading.alpha = 0
        submitOutlet.alpha = 1
    }
    
    //displays visual username error
    func usernameError(){
        usernameX.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.usernameX.alpha = 1
        }
    }
    //displays visual password error
    func passwordError(){
        passwordX.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.passwordX.alpha = 1
        }
    }
    //resets username and password errors
    func resetErrors(){
        usernameX.alpha = 0
        passwordX.alpha = 0
    }
    //validates username according to firebase requirements
    func validateUserInput(username:String) -> Bool{
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

    @IBAction func screenTap(_ sender: Any) {
        view.endEditing(true)
    }
    
    
}
