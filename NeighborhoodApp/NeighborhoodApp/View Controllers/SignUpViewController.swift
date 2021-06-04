//
//  SignUp.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/13/21.
//

import UIKit
import Firebase
import MHLoadingButton
class SignUpViewController: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    
    @IBOutlet weak var usernameX: UILabel!
    @IBOutlet weak var passwordX: UILabel!
    @IBOutlet weak var phoneX: UILabel!
    @IBOutlet weak var emailX: UILabel!
    
    
    @IBOutlet weak var submitOutlet: UIButton!
    
    private let btnLoading = LoadingButton(text: "Enter", textColor: .white, bgColor: UIColor(red: 247, green: 247, blue: 247, alpha: 0))
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //creates loading button
        btnLoading.frame = CGRect(x: 78, y: 479, width: 40, height: 40)
        btnLoading.indicator = MaterialLoadingIndicator(color: .blue)
        btnLoading.isUserInteractionEnabled = false
        btnLoading.showLoader(userInteraction: true)
        btnLoading.alpha = 0
        self.view.addSubview(btnLoading)
        
        resetErrors()

        
    }
    
    //MARK: loading animations
    private func startLoadingAnimation(){
        btnLoading.alpha = 1
        submitOutlet.alpha = 0
    }
    private func endLoadingAnimation(){
        btnLoading.alpha = 0
        submitOutlet.alpha = 1
    }
    
    //MARK: UI functions
    private func displayUsernameError(){
        usernameX.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.usernameX.alpha = 1
        }
    }
    private func displayPasswordError(){
        passwordX.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.passwordX.alpha = 1
        }
    }
    private func displayEmailError(){
        emailX.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.emailX.alpha = 1
        }
    }
    private func displayPhoneError(){
        phoneX.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.phoneX.alpha = 1
        }
    }
    private func resetErrors(){
        usernameX.alpha = 0
        passwordX.alpha = 0
        emailX.alpha = 0
        phoneX.alpha = 0
    }
    //dismisses keyboard on screen tap
    @IBAction func screenTap(_ sender: Any) {
        view.endEditing(true)
    }

    
    //MARK: Sign in handling
    @IBAction func submitBtn(_ sender: Any) {
        //clears UI errors
        resetErrors()
        
        //attempts to write to database
        let result = sendToDatabase()
        
        endLoadingAnimation()
        if(result == true){
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
        
    }
    //writes new user data to Firebase if textfields are acceptable
    private func sendToDatabase() -> Bool{
        //data to write to Firebase
        let username = (usernameTextField.text ?? "~//~").lowercased()
        let password = passwordTextField.text ?? "~//~"
        let neighborhoodID = ""
        let email = emailTextField.text ?? "~//~"
        let phone:String = phoneTextField.text ?? "xxx_xxx_xxxx"
        
        //textfield validation
        //validates username textfield
        var uiError = false
        if(!databaseSafeString(str: username)){
            //username error
            displayUsernameError()
            uiError = true
        }
        if(password == ""){
            //password error
            displayPasswordError()
            uiError = true
        }
        if(email == "" || !email.contains("@")){
            displayEmailError()
            uiError = true;
        }
        if(phone == "" || phone == "xxx_xxx_xxxx" || phone.count < 10){
            displayPhoneError()
            uiError = true;
        }
        if(uiError == true){
            return false
        }
        
    
        startLoadingAnimation()
        //writes specified data to Firebase
        return writeToDatabase(username: username, password: password, neighborhoodID: neighborhoodID, email: email, phone: phone, completion: { success in
            if(success == false){
                self.displayUsernameError()
            }
        })
        
    }
    
    private func writeToDatabase(username:String, password:String, neighborhoodID:String, email: String, phone:String, completion: @escaping (Bool) -> Void) -> Bool{
        //MARK: - Backdoor -
        return true
        
        let db = Firestore.firestore()
        var error:Bool = false
        
        db.collection("users").document(username).setData([
            "username": username,
            "password": password,
            "neighborhoodID": neighborhoodID,
            "email":email,
            "phone":phone
        ]) { err in
            if let _ = err {
                //error writing data
                completion(false)
                error = true
            } else {
                //success in writing data
                completion(true)
                error = false
            }
        }
        
        return !error
    }
    
    //determines whether a string is able to be stored in Firebase
    private func databaseSafeString(str:String) -> Bool{
        //makes sure username has contents
        if(str == ""){
            return false
        }
        //loops username for each character
        let pattern = "[0-9]|[a-z]"
        for letter in str{
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

    
    
}
