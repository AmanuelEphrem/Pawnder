//
//  HomeViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/8/21.
//

import UIKit
import MapKit
import Firebase
class HomeViewController: UIViewController, MKMapViewDelegate {
    
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
                    }
                }
            completion()
            }
        
    }
    //defines and displays annotations for users neighborhood
    private func displayAnnotations(){
        for pin in NeighborhoodData.pins{
            let annotation = MKPointAnnotation()
            annotation.title = pin.title
            annotation.subtitle = pin.description
            annotation.coordinate = CLLocationCoordinate2D(latitude: pin.locaiton.latitude, longitude: pin.locaiton.longitude)
            mapView.addAnnotation(annotation)
        }
    }
    
/*implements boundary for neighborhood*/
    //defines boundaries that represents the users neighborhood
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
