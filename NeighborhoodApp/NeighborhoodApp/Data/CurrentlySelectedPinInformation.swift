//
//  CurrentlySelectedPinInformation.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/15/21.
//

import UIKit
import MapKit
class CurrentlySelectedPinInformation: NSObject {
    public static var title = ""
    public static var description = ""
    public static var location = LocationData(latitude: -200, longitude: 200)
    public static var isUserPin = false
    public static var hash = -1

}
