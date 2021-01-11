//
//  HomeViewController.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/8/21.
//

import UIKit
import MapKit
class HomeViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()                          
        //draws neighborhood perimeter
        setNeighborhoodPerimeter(bounds: NeighborhoodData.boundaries, scale: 0.03)

        
            
    }
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
    
    func recenterMap(scale:Double){
        let cent = CLLocationCoordinate2D(latitude: NeighborhoodData.centerLocation.latitude, longitude: NeighborhoodData.centerLocation.longitude)
        mapView.centerCoordinate = cent
        mapView.setRegion(MKCoordinateRegion(center: cent, span: MKCoordinateSpan(latitudeDelta: scale, longitudeDelta: scale)), animated: true)
    }
    
    @IBAction func locationPressed(_ sender: Any) {
        recenterMap(scale: 0.03)
    }
    
    //shows user account screen
    @IBAction func accountPressed(_ sender: Any) {
        performSegue(withIdentifier: "MapToAccount", sender: nil)
    }
    
    @IBAction func mapPressed(_ sender: Any) {
    }
    
}
