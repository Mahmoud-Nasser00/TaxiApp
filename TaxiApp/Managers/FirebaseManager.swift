//
//  FirebaseManager.swift
//  TaxiApp
//
//  Created by Mahmoud Nasser on 12/04/2021.
//

import Foundation
import Firebase
import CoreLocation

class FirebaseManager: NSObject{
    
    static let shared = FirebaseManager()
    
    private let settings = FirestoreSettings()
    private let db = Firestore.firestore()
    
    override private init() {
        settings.isPersistenceEnabled = true
        db.settings = settings
    }
    
    func getLocationsDocs(completion: @escaping (_ locations:[SourceLocation],_ error:Error?)->Void ){
        let sourceCollection = Firestore.firestore().collection(Constants.FirebaseKeys.locationCollectionPath)
        
        sourceCollection.getDocuments { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot, error == nil else {
                completion([],error)
                debugPrint("Decoding error: \(String(describing: error))")
                return
            }
            
            var locations : [SourceLocation] = []
            
            for queryDoc in querySnapshot.documents {
                do {
                    let location:SourceLocation =  try queryDoc.queryDecoded()
                    locations.append(location)
                } catch let error {
                    debugPrint("Decoding error: \(error)")
                    completion([],error)
                }
            }
            
            completion(locations,nil)
            
        }
        
    }
    
    func getDriverDocs(completion:@escaping(_ drivers:[Driver],_ error:Error?)->Void){
        let driverCollection = Firestore.firestore().collection(Constants.FirebaseKeys.driversCollectionPath)
        
        driverCollection.getDocuments { (querySnapshot, error) in
            guard let querySnapshot = querySnapshot, error == nil else {
                completion([],error)
                debugPrint("Decoding error: \(String(describing: error))")
                return
            }
            
            var drivers:[Driver] = []
            
            for queryDoc in querySnapshot.documents {
                do {
                    let driver:Driver = try queryDoc.queryDecoded()
                    drivers.append(driver)
                } catch let error {
                    debugPrint("Decoding error: \(error)")
                    completion([],error)
                }
                completion(drivers,nil)
            }
        }
    }
    
    func getClosestDrivers(drivers:[Driver],closestToLocation location:CLLocation) -> [Driver]{
        drivers.sorted(by: {
            location.distance(from: $0.comparableCoordinate) < location.distance(from: $1.comparableCoordinate)
        })
    }
    
}

extension QueryDocumentSnapshot {
    func queryDecoded<T:Codable>() throws -> T {
        let json = try JSONSerialization.data(withJSONObject: data(), options: [])
        let object = try JSONDecoder().decode(T.self, from: json)
        return object
    }
}
