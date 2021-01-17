//
//  HomeViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/8/21.
//

import UIKit
import MapKit
import Firebase
class HomeViewController: UIViewController, MKMapViewDelegate{
    
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
        //draws neighborhood perimeter
        setNeighborhoodPerimeter(bounds: NeighborhoodData.boundaries, scale: 0.03)
        
        //listens for old and new pins
        pinListener()
        
    }
     
/*fetches pins from database in real-time*/
    //setup database listener
    func pinListener(){
        //quits if there's no neighborhood
        if(PersonalData.neighborhoodID == ""){
            print("not part of a neighborhood...yet")
            return
        }
        
        retrievePins {
            //adds pins to map
            self.displayAnnotations()
        }
        
    }
    //updates NeighborhoodData class with pin data
    private func retrievePins(completion: @escaping () -> Void){
        let db = Firestore.firestore()
        var title:String = ""
        var description:String = ""
        var id:String = ""
        var location:[Double] = [-5.0,-6.0]
        
        db.collection("neighborhood").document(PersonalData.neighborhoodID).collection("pins").addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error retrieving pins")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added ) {
                        //retrieves data
                        let info = diff.document.data()
                        title = info["title"] as! String
                        description = info["description"] as! String
                        id = info["ID"] as! String
                        location = info["location"] as! [Double]
                        
                        //sets data
                        NeighborhoodData.pins.append(PinData(title: title, description: description, ID: id, locaiton: LocationData(latitude: location[0], longitude: location[1])))
                        
                    }else if(diff.type == .removed){
                        let identification = diff.document.data()["ID"] as! String
                        self.removePinFromCollection(identification: identification)
                        self.displayAnnotations()
                    }
                }
            completion()
            }
        
    }
    //returns annotation with corresponding hash
    private func findAnnotation(hash:Int) -> MKAnnotation{
        for annotation in mapView.annotations{
            if(annotation.hash == hash){
                return annotation
            }
        }
        return MKPointAnnotation()
    }
    //removes pin with corresponding has from array
    private func removePinFromCollection(identification:String){
        print(NeighborhoodData.pins.count)
        //if there are no pins exit
        if(NeighborhoodData.pins.count <= 0){
            return
        }
        for index in 0...NeighborhoodData.pins.count-1{
            if(NeighborhoodData.pins[index].ID == identification){
                NeighborhoodData.pins.remove(at: index)
                return
            }
        }
    }
    //defines and displays annotations for users neighborhood
    private func displayAnnotations(){
        //clears all annotations
        mapView.removeAnnotations(mapView.annotations)
        for pin in NeighborhoodData.pins{
            //adds annotations
            let annotation = MKPointAnnotation()
            annotation.title = pin.title
            annotation.subtitle = pin.description
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.locaiton.latitude, longitude: pin.locaiton.longitude)
            //checks if this pin is users
            if(PersonalData.personalPins.contains(pin.ID) == true){
                PersonalData.pinHash.append(annotation.hash)
                PersonalData.relationship[annotation.hash] = pin.ID
            }
            mapView.addAnnotation(annotation)
        }
    }
    
/*implements boundary for neighborhood*/
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
        //quits if there's no neighborhood
        if(PersonalData.neighborhoodID == ""){
            print("not part of a neighborhood...yet")
            return
        }
        
        let cent = CLLocationCoordinate2D(latitude: NeighborhoodData.centerLocation.latitude, longitude: NeighborhoodData.centerLocation.longitude)
        mapView.centerCoordinate = cent
        mapView.setRegion(MKCoordinateRegion(center: cent, span: MKCoordinateSpan(latitudeDelta: scale, longitudeDelta: scale)), animated: true)
    }
    //prevents disappearing annotations
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseIdentifier = "annotationView"
        var view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier)
        if #available(iOS 11.0, *) {
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            }
            view?.displayPriority = .required
        } else {
            if view == nil {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            }
        }
        view?.annotation = annotation
        view?.canShowCallout = true
        return view
    }
    
/*defines action for pin tap*/
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //saves current annotation in class
        CurrentlySelectedPinInformation.title = view.annotation!.title!!
        CurrentlySelectedPinInformation.description = view.annotation!.subtitle!!
        CurrentlySelectedPinInformation.location = LocationData(latitude: view.annotation!.coordinate.latitude.magnitude, longitude: (-1.0)*(view.annotation!.coordinate.longitude.magnitude))
        CurrentlySelectedPinInformation.isUserPin = PersonalData.pinHash.contains(view.annotation!.hash)
        CurrentlySelectedPinInformation.hash = view.annotation!.hash
        
        //changes view
        performSegue(withIdentifier: "MapToPinView", sender: nil)
    }
    
    
/*defines actions for tab icons*/
    //recenter tab pressed
    @IBAction func locationPressed(_ sender: Any) {
        recenterMap(scale: 0.03)
    }
    //account tab pressed that switches view
    @IBAction func accountPressed(_ sender: Any) {
        performSegue(withIdentifier: "MapToAccount", sender: nil)
    }
    //map tab pressed that switches view
    @IBAction func mapPressed(_ sender: Any) {
        performSegue(withIdentifier: "MapToPinMake", sender: nil)
    }
    
}
