//
//  MakePinViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/14/21.
//

import UIKit
import MapKit
import Firebase
import MHLoadingButton
class MakePinViewController: UIViewController, MKMapViewDelegate{

    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var lockBtnOutlet: UIButton!
    @IBOutlet weak var usernameX: UILabel!
    @IBOutlet weak var passwordX: UILabel!
    @IBOutlet weak var saveBtnOutlet: UIButton!
    
    
    //instance variables
    private var isLocked = false
    private var annotationTitle = "New Annotation"
    private var annotationDescription = ""
    private var currentAnnotation:MKPointAnnotation? = nil
    private var documentID = ""
    private var success = false
    let btnLoading = LoadingButton(text: "Enter", textColor: .white, bgColor: UIColor(red: 0, green: 0, blue: 0, alpha: 0))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //createas loading button
        btnLoading.frame = CGRect(x: 68, y: 221, width: 35, height: 35)
        btnLoading.indicator = MaterialLoadingIndicator(color: .blue)
        btnLoading.isUserInteractionEnabled = false
        btnLoading.showLoader(userInteraction: true)
        btnLoading.alpha = 0
        self.view.addSubview(btnLoading)
        
        //sets up error UI
        resetErrors()
        
        //sets map view
        setNeighborhoodPerimeter(bounds: NeighborhoodData.boundaries, scale: 0.03)
    }
    
    
    //writes data to firebase
    @IBAction func saveBtn(_ sender: Any) {
        //saves textfield info in case editing was not finished
        annotationTitle = titleTextField.text!
        annotationDescription = descriptionTextField.text!
        
        //resets screen UI errors
        resetErrors()
        //makes sure textfields have content
        if(titleTextField.text! == "" || descriptionTextField.text! == "" || currentAnnotation == nil){
            if(titleTextField.text! == ""){
                titleError()
            }
            if(descriptionTextField.text! == ""){
                descriptionError()
            }
            if(currentAnnotation == nil){
                titleError()
                descriptionError()
            }
            return
        }
        
        //writes data to database while showing loading animation
        startLoading()
        updateUserPins {

            if(self.success == true){
                //make changes to user profile to document change
                self.writeAnnotationToDatabase {
                    //ends loading animation because writing has ended
                    self.endLoading()
                    //changes view
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            }else{
                //ends loading animation because writing has ended
                self.endLoading()
            }
        }
        
    }
    //sends annotation info to database
    func writeAnnotationToDatabase(completion: @escaping () -> Void){
        //writes data to database
        let db = Firestore.firestore()

        let location:[Double] = [currentAnnotation!.coordinate.latitude.magnitude,(currentAnnotation!.coordinate.longitude.magnitude * -1.0)]
        db.collection("neighborhood").document(PersonalData.neighborhoodID).collection("pins").document(documentID).setData([
            "title": annotationTitle,
            "description": annotationDescription,
            "location": location,
            "ID": String(documentID)
        ]) { err in
            if err != nil {
                print("error uploading annotation to database!")
                self.success = false
                completion()
            } else {
                self.success = true
                completion()
            }
        }
    }
    //updates user pins
    func updateUserPins(completion: @escaping () -> Void){
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(PersonalData.username)
        
        //creates document id
        let docid = UUID().uuidString
        
        //makes sure changes need to be written
        if(placePinAppropriately(pinID: docid) == false){
            self.success = false
            completion()
            return
        }
        
        //save docid
        documentID = docid
        
        // updates pins data field
        docRef.updateData([
            "pins": PersonalData.personalPins
        ]) { err in
            if err != nil {
                print("Error updating user personal pin data when creating pin")
                self.titleError()
                self.descriptionError()
                self.success = false
                completion()
            } else {
                self.success = true
                completion()
            }
        }
    }
    
    //helper function to appropriately place value in array
    private func placePinAppropriately(pinID:String) -> Bool{
        for index in 0...PersonalData.personalPins.count-1{
            if(PersonalData.personalPins[index] == "-1"){
                PersonalData.personalPins[index] = pinID
                return true
            }
        }
        return false
    }
    
/*defines UI error labels*/
    private func titleError(){
        UIView.animate(withDuration: 0.5) {
            self.usernameX.alpha = 1
        }
        
    }
    private func descriptionError(){
        UIView.animate(withDuration: 0.5) {
            self.passwordX.alpha = 1
        }
    }
    private func resetErrors(){
        usernameX.alpha = 0;
        passwordX.alpha = 0
    }
    private func startLoading(){
        btnLoading.alpha = 1
        saveBtnOutlet.alpha = 0
    }
    private func endLoading(){
        btnLoading.alpha = 0
        saveBtnOutlet.alpha = 1
    }
    
/*defines functions for textfield*/
    @IBAction func titleTextFieldDidEnd(_ sender: Any) {
        annotationTitle = titleTextField.text!
        updateMapAnnotation()
    }
    @IBAction func descriptionTextFieldDidEnd(_ sender: Any) {
        annotationDescription = descriptionTextField.text!
        updateMapAnnotation()
    }
    
    
/*defines functions for mapkit*/
    //defines boundaries that represents the users neighborhood
    func setNeighborhoodPerimeter(bounds:[LocationData], scale:Double){
        //quits if there's no neighborhood
        if(PersonalData.neighborhoodID == ""){
            print("not part of a neighborhood...yet")
            return
        }
        
        var coords = [CLLocationCoordinate2D]()
        //converts boundary points to coordinates
        for point in bounds{
            coords.append(CLLocationCoordinate2D(latitude: point.latitude, longitude: point.longitude))
        }
        coords.append(CLLocationCoordinate2D(latitude: bounds[0].latitude, longitude: bounds[0].longitude))
        
        let testline = MKPolyline(coordinates: coords, count: coords.count)

        //Add `MKPolyLine` as an overlay.
        mapView.addOverlay(testline)
        
        //sets delegates
        mapView.delegate = self
        
        //sets map to center of neighborhood
        recenterMap(scale: scale)
    }
    //draws the boundary for users neighborhood
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            //Return an `MKPolylineRenderer` for the `MKPolyline` in the `MKMapViewDelegate`s method

        if let polyline = overlay as? MKPolyline {
                let testlineRenderer = MKPolylineRenderer(polyline: polyline)
                testlineRenderer.strokeColor = .red
                testlineRenderer.lineWidth = 1
                return testlineRenderer
            }
            fatalError("Something wrong in renderfor function...")

    }
    //realigns map to users neighborhood
    func recenterMap(scale:Double){
        let cent = CLLocationCoordinate2D(latitude: NeighborhoodData.centerLocation.latitude, longitude: NeighborhoodData.centerLocation.longitude)
        mapView.centerCoordinate = cent
        mapView.setRegion(MKCoordinateRegion(center: cent, span: MKCoordinateSpan(latitudeDelta: scale, longitudeDelta: scale)), animated: true)
    }
    
    //plots annotation when user *double* taps screen
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //quits if there's no neighborhood
        if(PersonalData.neighborhoodID == ""){
            print("not part of a neighborhood...yet")
            return
        }
        
        for touch in touches {
            let touchPoint = touch.location(in: mapView)
            let location = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            if(touch.tapCount == 2){
                //only adds an annotation if point is in bounds
                if(pointInBounds(point: LocationData(latitude: location.latitude, longitude: location.longitude)) == false){
                    return
                }
                
                //clears map annotations
                let allAnnotations = mapView.annotations
                mapView.removeAnnotations(allAnnotations)
                //defines a new annotation
                let annotation = MKPointAnnotation()
                annotation.title = annotationTitle
                annotation.subtitle = annotationDescription
                annotation.coordinate = CLLocationCoordinate2D(latitude: location.latitude , longitude: location.longitude)
                currentAnnotation = annotation
                mapView.addAnnotation(annotation)

            }
            
        }
    }
    //helper function for touchesBegan
    private func pointInBounds(point:LocationData) -> Bool{
        let topLeft = NeighborhoodData.boundaries[0]
        let topRight = NeighborhoodData.boundaries[1]
        let bottomRight = NeighborhoodData.boundaries[2]
        let bottomLeft = NeighborhoodData.boundaries[3]
        
        //checks if 'point' is inside box made up of 4 locations
        //this method works only in North America
        if(point.latitude <= topLeft.latitude && point.longitude >= topLeft.longitude){
            if(point.latitude <= topRight.latitude && point.longitude <= topRight.longitude){
                if(point.latitude >= bottomLeft.latitude && point.longitude >= bottomLeft.longitude){
                    if(point.latitude >= bottomRight.latitude && point.longitude <= bottomRight.longitude){
                        return true
                    }
                }
            }
        }
        return false
    }
    
    //updates map annotation
    func updateMapAnnotation(){
        if(currentAnnotation == nil){
            //no annotation is defined yet
            return
        }
        
        //redefines annotation
        currentAnnotation?.title = annotationTitle
        currentAnnotation?.subtitle = annotationDescription
    }
    
    //disables/enables map movement. Acts as a switch
    @IBAction func lockBtn(_ sender: Any) {
        if(isLocked == true){
            //changes UI
            isLocked = false
            lockBtnOutlet.setTitle("Unlocked")
            //changes map functionality
            mapView.isZoomEnabled = true
            mapView.isScrollEnabled = true
        }else{
            //changes UI
            isLocked = true
            lockBtnOutlet.setTitle("Locked")
            //changes map functionality
            mapView.isZoomEnabled = false
            mapView.isScrollEnabled = false
        }
    }
    
    //resigns keyboard
    @IBAction func screenTap(_ sender: Any) {
        view.endEditing(true)
    }
    
}
