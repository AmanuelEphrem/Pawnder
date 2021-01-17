//
//  NeighborhoodData.swift
//  NeighborhoodApp
//
//  Created by Amanuel Ephrem on 1/10/21.
//

import UIKit

class NeighborhoodData: NSObject {
    public static var boundaries = [LocationData](){
        didSet{
            //makes sure boundaries has content
            if(boundaries.count < 2){
                return
            }
            //compute centerLocation
            var centerLat = 0.0
            var centerLong = 0.0
            for index in 0...boundaries.count-2{
                centerLat += boundaries[index].latitude
                centerLong += boundaries[index].longitude
            }
            centerLocation.latitude = centerLat/(Double((boundaries.count-1))*1.0)
            centerLocation.longitude = centerLong/(Double((boundaries.count-1))*1.0)
        }
    }
    public static var centerLocation:LocationData = LocationData(latitude: -200, longitude: 200)
    public static var code = -1
    public static var password = ""
    public static var description = ""
    public static var organizer = ""
    public static var pins = [PinData]()
    public static var name = ""

}
