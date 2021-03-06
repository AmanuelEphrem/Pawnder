//
//  ViewPinViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/15/21.
//

import UIKit
import MapKit
import Firebase
class ViewPinViewController: UIViewController, MKMapViewDelegate {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var deleteBtnOutlet: UIButton!
    @IBOutlet weak var lockBtnOutlet: UIButton!
    
    //instance data
    private var isLocked = false
    override func viewDidLoad() {
        super.viewDidLoad()
        //draws neighborhood perimeter
        setNeighborhoodPerimeter(bounds: NeighborhoodData.boundaries, scale: 0.03)
        
        //draws single point user clicked
        markPoint()
        
        //sets up UI for text
        setupUI()
        
        print(PersonalData.personalPins)
    }
    
    //sets up UI
    func setupUI(){
        //sets text to correct values
        titleLabel.text = CurrentlySelectedPinInformation.title
        descriptionLabel.text = "                       "+CurrentlySelectedPinInformation.description
        descriptionLabel.sizeToFit()
        
        //centers map view around point
        let pin = CLLocationCoordinate2D(latitude: CurrentlySelectedPinInformation.location.latitude, longitude: CurrentlySelectedPinInformation.location.longitude)
        mapView.centerCoordinate = pin
        mapView.setRegion(MKCoordinateRegion(center: pin, span: MKCoordinateSpan(latitudeDelta: 0.002, longitudeDelta: 0.002)), animated: true)

        //presents delete button if user owns pin
        //currently functionality is not working
        if(CurrentlySelectedPinInformation.isUserPin == true){
            deleteBtnOutlet.alpha = 1
            deleteBtnOutlet.isUserInteractionEnabled = true
        }else{
            deleteBtnOutlet.alpha = 0
            deleteBtnOutlet.isUserInteractionEnabled = false
        }
        
    }
    
    //marks point user clicked on map
    func markPoint(){
        let annotation = MKPointAnnotation()
        annotation.title = CurrentlySelectedPinInformation.title
        annotation.subtitle = CurrentlySelectedPinInformation.description
        annotation.coordinate = CLLocationCoordinate2D(latitude: CurrentlySelectedPinInformation.location.latitude, longitude: CurrentlySelectedPinInformation.location.longitude)
        mapView.addAnnotation(annotation)
    }
    
/*implements boundary for neighborhood*/
    func setNeighborhoodPerimeter(bounds:[LocationData], scale:Double){
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
    
    //delets current post
    //not currently working
    @IBAction func deleteBtn(_ sender: Any) {
        //attempts to delete pin
        deleteCurrentAnnotation { (success) in
            if(success == true){
                //deletes from user database
                self.deleteFromUser {
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                }
            }else{
                //give error animation
            }
        }
    }
    //deletes current annotation from neighborhood
    func deleteCurrentAnnotation(completion: @escaping (Bool) -> Void){
        let db = Firestore.firestore()
        db.collection("neighborhood").document(NeighborhoodData.name).collection("pins").document(PersonalData.relationship[CurrentlySelectedPinInformation.hash]!).delete() { err in
            if err != nil {
                print("Error deleting pin")
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    //saves user changes to username data
    func deleteFromUser(completion: @escaping () -> Void){
        let db = Firestore.firestore()
        removeElement(value: PersonalData.relationship[CurrentlySelectedPinInformation.hash]!)
        db.collection("users").document(PersonalData.username).updateData([
            "pins": PersonalData.personalPins
        ]) { err in
            if err != nil {
                print("Error writing document in join neighborhood:")
                completion()
            } else {
                completion()
            }
        }
    }
    //removes specified value from copy of personal pins
    private func removeElement(value:String){
        let value = PersonalData.relationship[CurrentlySelectedPinInformation.hash]!
        if(PersonalData.personalPins[0] == value){
            PersonalData.personalPins[0] = String(-1)
        }
        if(PersonalData.personalPins[1] == value){
            PersonalData.personalPins[1] = String(-1)
        }
        if(PersonalData.personalPins[2] == value){
            PersonalData.personalPins[2] = String(-1)
        }
    }
    
    //disables/enables map movement. Acts as a switch
    @IBAction func lockBtn(_ sender: Any) {
        //changes ui
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
}
