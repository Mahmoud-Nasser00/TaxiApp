//
//  ViewController.swift
//  TaxiApp
//
//  Created by Mahmoud Nasser on 11/04/2021.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController {

    @IBOutlet weak var cardView:UIView! {
        didSet{
            cardView.layer.cornerRadius = 10
            cardView.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var menuBtn:UIButton! {
        didSet {
            menuBtn.layer.cornerRadius = menuBtn.frame.size.height / 2
            menuBtn.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var locationTF:UITextField!
    @IBOutlet weak var destinationTF:UITextField!
    
    //MARK:- Variables
    
    let locationManager = CLLocationManager()
    var mapView: GMSMapView!
    
    //MARK:- App Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        getUserLocation()

    }

    //MARK:- UIFunctions

    private func addMapToMainView(withLocation location:CLLocationCoordinate2D , zoom: Float){
        let camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: zoom)
        self.mapView = GMSMapView(frame: self.view.frame, camera: camera)
        self.view.addSubview(mapView)
        view.bringSubviewToFront(cardView)
    }
    
    private func addMarkerToMapView(withLocation location:CLLocationCoordinate2D){
        let marker = GMSMarker()
        marker.position = location
        marker.map = mapView
    }
    
    
    //MARK:- Helper Functions
    
    private func getUserLocation(){
        
        // Ask for Authorisation's from the User.
        self.locationManager.requestAlwaysAuthorization()

        // For use in foreground
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    //MARK:- IBActions
    
    @IBAction func menuBtnTapped(_ sender:UIButton){
        print(1)
    }
    
}

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        addMapToMainView(withLocation: locValue, zoom: 7)
        addMarkerToMapView(withLocation: locValue)
        
           print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
    
  
}
