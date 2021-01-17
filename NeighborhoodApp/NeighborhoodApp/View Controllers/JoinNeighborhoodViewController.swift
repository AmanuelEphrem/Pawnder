//
//  JoinNeighborhoodViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/16/21.
//

import UIKit
import Firebase
import MHLoadingButton
class JoinNeighborhoodViewController: UIViewController {

    @IBOutlet weak var codeTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var codeX: UILabel!
    @IBOutlet weak var passwordX: UILabel!
    
    //outlets for labels/button
    @IBOutlet weak var neighborhoodName: UILabel!
    @IBOutlet weak var organizerName: UILabel!
    @IBOutlet weak var codeName: UILabel!
    @IBOutlet weak var passwordName: UILabel!
    @IBOutlet weak var noGroupLabel: UILabel!
    @IBOutlet weak var successDescription: UILabel!
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var joinBtnOutlet: UIButton!
    let btnLoading = LoadingButton(text: "Enter", textColor: .white, bgColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0))
    
    
    //labels that don't change text
    @IBOutlet weak var organizerDisplay: UILabel!
    @IBOutlet weak var codeDisplay: UILabel!
    @IBOutlet weak var passwordDisplay: UILabel!
    
    //instance data
    private var isCredentialsGood = false
    private var newNeighborhood = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
    }
    
    func setupUI(){
        //no errors on startup
        resetErrors()

        //creates loading button
        btnLoading.frame = CGRect(x: 70, y: 260, width: 35, height: 35)
        btnLoading.indicator = MaterialLoadingIndicator(color: .blue)
        btnLoading.isUserInteractionEnabled = false
        btnLoading.showLoader(userInteraction: true)
        btnLoading.alpha = 0
        self.view.addSubview(btnLoading)
        
        //shows appropriate message based off which group
        if(NeighborhoodData.name == ""){
            noGroup()
        }else{
            groupAvailable(name: NeighborhoodData.name, org: NeighborhoodData.organizer, code: String(NeighborhoodData.code), password: NeighborhoodData.password)
        }
    }
/*error UI */
    func codeError(){
        codeX.alpha = 1;
    }
    func passwordError(){
        passwordX.alpha = 1
    }
    func resetErrors(){
        codeX.alpha = 0
        passwordX.alpha = 0
    }

/*message label UI*/
    func noGroup(){
        //sets UI
        neighborhoodName.alpha = 1
        organizerName.alpha = 0
        codeName.alpha = 0
        passwordName.alpha = 0
        organizerDisplay.alpha = 0
        codeDisplay.alpha = 0
        passwordDisplay.alpha = 0
        successDescription.alpha = 0
        logoutBtn.alpha = 0
        noGroupLabel.alpha = 1
        
        //sets text
        neighborhoodName.text = "No group yet..."
        noGroupLabel.text = "Information regarding your neighborhood"
    }
    func groupAvailable(name:String,org:String,code:String,password:String){
        //sets UI
        neighborhoodName.alpha = 1
        organizerName.alpha = 1
        codeName.alpha = 1
        passwordName.alpha = 1
        organizerDisplay.alpha = 1
        codeDisplay.alpha = 1
        passwordDisplay.alpha = 1
        noGroupLabel.alpha = 0
        successDescription.alpha = 0
        logoutBtn.alpha = 0
        
        //sets text
        neighborhoodName.text = name
        organizerName.text = org
        codeName.text = code
        passwordName.text = password
    }
    func groupLogIn(){
        //sets UI
        organizerName.alpha = 0
        codeName.alpha = 0
        passwordName.alpha = 0
        organizerDisplay.alpha = 0
        codeDisplay.alpha = 0
        passwordDisplay.alpha = 0
        noGroupLabel.alpha = 0
        UIView.animate(withDuration: 0.5) {
            self.neighborhoodName.alpha = 1
            self.successDescription.alpha = 1
            self.logoutBtn.alpha = 1
        }
        logoutBtn.isEnabled = true
        
        //sets text
        neighborhoodName.text = "Success!"
        noGroupLabel.text = "Log in again to see changes"
    }

/*loading button UI*/
    func startLoading(){
        joinBtnOutlet.alpha = 0
        btnLoading.alpha = 1
    }
    func endLoading(){
        joinBtnOutlet.alpha = 1
        btnLoading.alpha = 0
    }
    
    /*changes neighborhood for user*/
    @IBAction func joinBtn(_ sender: Any) {
        //resets errors
        resetErrors()
        
        //changes user neighborhood if credentials match and begins loading animation
        startLoading()
        checksCredentials {
            if(self.isCredentialsGood == true){
                //saves changes
                self.saveNeighborhoodChanges {
                    self.deleteUserPins {
                        //end loading animation
                        self.endLoading()
                        //changes saved, prompt user to log out
                        self.groupLogIn()
                        
                        //reset values
                        self.isCredentialsGood = false;
                        self.newNeighborhood = ""
                        //PersonalData.isLoggingOut = false
                    }
                }
            }
            //end loading animation
            self.endLoading()
        }
    }
    //checks if credentials given matches
    func checksCredentials(completion: @escaping () -> Void){
        let db = Firestore.firestore()
        db.collection("neighborhood").getDocuments() { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    self.isCredentialsGood = false
                    completion()
                } else {
                    for document in querySnapshot!.documents {
                        //gets relevant data from database
                        let info = document.data()
                        let code = info["code"] as! Int
                        let password = info["password"] as! String
                        
                        //checks if credentials match
                        if(self.codeTextField.text == String(code)){
                            if(self.passwordTextField.text == password){
                                //credentials match
                                self.isCredentialsGood = true
                                self.newNeighborhood = document.documentID
                                completion()
                                return
                            }else{
                                //password is wrong and don't check anymore docs
                                self.passwordError()
                                self.isCredentialsGood = false
                                completion()
                            }
                        }
                    }
                    //code is wrong
                    self.codeError()
                    self.isCredentialsGood = false
                    completion()
                }
        }
    }
    //saves user changes to username data
    func saveNeighborhoodChanges(completion: @escaping () -> Void){
        let db = Firestore.firestore()
        let emptyPins:[String] = ["-1","-1","-1"]
        db.collection("users").document(PersonalData.username).updateData([
            "neighborhoodID": self.newNeighborhood,
            "pins": emptyPins
        ]) { err in
            if err != nil {
                print("Error writing document in join neighborhood:")
                self.codeError()
                self.passwordError()
                completion()
            } else {
                completion()
            }
        }
    }
    //deletes user pins from neighborhood
    func deleteUserPins(completion: @escaping () -> Void){
        //retrieves pin id's
        retrievePinID { (list) in
            let db = Firestore.firestore()
            for identificaiton in list{
                db.collection("neighborhood").document(PersonalData.neighborhoodID).collection("pins").document(identificaiton).delete()
            }
            completion()
        }
    }
    //retrieves array of relevant pin ID's
    func retrievePinID(completion: @escaping ([String]) -> Void){
        let db = Firestore.firestore()
        var identification = ""
        var relevantPins = [String]()
        db.collection("neighborhood").document(PersonalData.neighborhoodID).collection("pins").getDocuments() { (querySnapshot, err) in
            if err != nil {
                    print("Error getting documents while retrieving all pins")
                    completion(relevantPins)
                } else {
                    for document in querySnapshot!.documents {
                        identification = document.data()["ID"] as! String
                        if(PersonalData.personalPins.contains(identification)){
                            relevantPins.append(identification)
                        }
                    }
                    completion(relevantPins)
                }
        }
    }
    @IBAction func backArrow(_ sender: Any) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func logOutBtnAction(_ sender: Any) {
        //reset data
        resetLocalData()
        //change views
        self.presentingViewController?.presentingViewController?.presentingViewController?.dismiss(animated: false, completion: nil)
    }
    
    //clears local data
    private func resetLocalData(){
       //reset necessary personal data
        PersonalData.personalPins.removeAll()
        PersonalData.pinHash.removeAll()
        PersonalData.relationship.removeAll()
        
        //resets neighborhood Data
        NeighborhoodData.boundaries.removeAll()
        NeighborhoodData.pins.removeAll()
    }
    
    
    @IBAction func screenTap(_ sender: Any) {
        view.endEditing(true)
    }
}
