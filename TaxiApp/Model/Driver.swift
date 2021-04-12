//
//  Driver.swift
//  TaxiApp
//
//  Created by Mahmoud Nasser on 12/04/2021.
//

import Foundation
import CoreLocation

struct Driver: Codable , Equatable {
    
    let name:String
    let longitude:Double
    let latitude:Double
    
    var coordinate:CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var comparableCoordinate:CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
}
