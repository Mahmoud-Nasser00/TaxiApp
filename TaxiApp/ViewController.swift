//
//  ViewController.swift
//  TaxiApp
//
//  Created by Mahmoud Nasser on 11/04/2021.
//

import UIKit
import GoogleMaps
import GooglePlaces

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
    @IBOutlet weak var locationTF:UITextField!{
        didSet {
            locationTF.delegate = self
        }
    }
    @IBOutlet weak var destinationTF:UITextField!{
        didSet {
            destinationTF.delegate = self
        }
    }
    @IBOutlet weak var locationsTV:UITableView! {
        didSet {
            locationsTV.delegate = self
            locationsTV.dataSource = self
            locationsTV.isHidden = true
            locationsTV.layer.cornerRadius = 10
            locationsTV.layer.masksToBounds = true
        }
    }
    @IBOutlet weak var requestRDBtn:UIButton!{
        didSet {
            requestRDBtn.addingShadowAndCornerRadius()
        }
    }
    
    //MARK:- Variables
    
    private var mapView: GMSMapView!
    private var placesTableViewDataSource: GMSAutocompleteTableDataSource!
    
    
    private let firebaseManager = FirebaseManager.shared
    private let locationManager = CLLocationManager()
    
    
    private var userCurrentLocation :CLLocation?
    
    private var selectedSourceLocation:SourceLocation! {
        didSet {
            locationTF.text = selectedSourceLocation.name
        }
    }
    
    private var locations = [SourceLocation]()
    private var drivers = [Driver]()
    
    private var searchedLocations:[SourceLocation] = []
    private var searchedDestinations = [GMSPlace]()
    
    private var isDestinationSearchActive:Bool = false
    
    //MARK:- App Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addMapToMainView()
        getUserLocation()
        
        getSourceLocations()
        getDrivers()
    }
    
    //MARK:- UIFunctions

    private func addMapToMainView(){
        self.mapView = GMSMapView(frame: self.view.frame)
        self.view.addSubview(mapView)
        view.bringSubviewToFront(cardView)
        view.bringSubviewToFront(locationsTV)
        view.bringSubviewToFront(requestRDBtn)
    }
    
    private func addMarkerToMapView(withLocation location:CLLocationCoordinate2D){
        let marker = GMSMarker()
        marker.position = location
        marker.map = mapView
    }
    
    private func updateMapView(with location:CLLocationCoordinate2D,zoom:Float? = 9){
        let camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: zoom!)
        mapView.camera = camera
        addMarkerToMapView(withLocation: location)
    }
    
    //not used
    private func addMainViewGesture(){
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        view.addGestureRecognizer(tapGesture)
    }
    
    //MARK:- Helper Functions
    
    private func getUserLocation(){
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    private func getSourceLocations(){
        firebaseManager.getLocationsDocs { [weak self] (locations, error) in
            guard let self = self ,locations.count != 0 , error == nil else {return}
            self.locations = locations
            self.locationsTV.reloadData()
        }
    }
    
    private func getDrivers(){
        firebaseManager.getDriverDocs { [weak self] (drivers, error) in
            guard let self = self ,drivers.count != 0 , error == nil else {return}
            self.drivers = drivers
        }
    }
    
    func getClosestDriver(drivers:[Driver],closestToLocation location:CLLocation) -> Driver? {
        if let closestDriver = drivers.min(by: {
            location.distance(from: $0.comparableCoordinate) < location.distance(from: $1.comparableCoordinate)
        }) {
            print("closest Driver: \(closestDriver), distance: \(location.distance(from: closestDriver.comparableCoordinate))")
            return closestDriver
        } else {
            print("coordinates is empty")
            return nil
        }
    }
    
    //not used
    func getClosestLocation(locations: [CLLocation], closestToLocation location: CLLocation) -> CLLocation? {
        
        if let closestLocation = locations.min(by: { location.distance(from: $0) < location.distance(from: $1) }) {
            print("closest location: \(closestLocation), distance: \(location.distance(from: closestLocation))")
            return closestLocation
        } else {
            print("coordinates is empty")
            return nil
        }
    }

    /// places autocomplete
    //not used
    private func setupPlacesTableView(){
        placesTableViewDataSource = GMSAutocompleteTableDataSource()
        placesTableViewDataSource.delegate = self
        
        var currentLoc:CLLocation
        
        let fields = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) | UInt(GMSPlaceField.placeID.rawValue))
        placesTableViewDataSource.placeFields = fields
        
        // Specify a filter.
        let filter = GMSAutocompleteFilter()
        // Specify type filter
        filter.type = .establishment
        // Specify location bias filter
        if(CLLocationManager.authorizationStatus() == .authorizedWhenInUse ||
              CLLocationManager.authorizationStatus() == .authorizedAlways) {
            currentLoc = locationManager.location!
            let _ = CLLocationCoordinate2D(latitude: currentLoc.coordinate.latitude, longitude:currentLoc.coordinate.longitude)
            print("lat",currentLoc.coordinate.latitude)
            print("long",currentLoc.coordinate.longitude)
            filter.locationBias = GMSPlaceRectangularLocationOption(currentLoc.coordinate, currentLoc.coordinate)
            placesTableViewDataSource.autocompleteFilter = filter
        }
        
        locationsTV.delegate = placesTableViewDataSource
        locationsTV.dataSource = placesTableViewDataSource
    }
    
    // get places near to current location
    private func listLikelyPlaces() {
        searchedDestinations.removeAll()

      let placeFields: GMSPlaceField = [.name, .coordinate]
        GMSPlacesClient.shared().findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: placeFields) { (placeLikelihoods, error) in
        guard error == nil else {
          print("Current Place error: \(error!.localizedDescription)")
          return
        }

        guard let placeLikelihoods = placeLikelihoods else {
          print("No places found.")
          return
        }

        for likelihood in placeLikelihoods {
          let place = likelihood.place
            print(place)
          self.searchedDestinations.append(place)
        }
      }
    }
    
    private func showAlert(title:String, message:String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .cancel)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
   
    
    //MARK:- IBActions
    
    @IBAction func menuBtnTapped(_ sender:UIButton){
        
        if !locationsTV.isHidden {
            sender.isSelected = !sender.isSelected
        }
        
        view.endEditing(true)
        locationsTV.isHidden = true
    }
    
    @IBAction func sourceLocationTFEditingChanged(_ sender: UITextField) {
    }
    
    @IBAction func destinationTFEditingChanged(_ sender: UITextField) {
        print(sender.text!)
        placesTableViewDataSource.sourceTextHasChanged(sender.text!)
    }
    
    @IBAction func requestRDBtnTapped(_ sender:UIButton){
        guard let location = userCurrentLocation else {
            showAlert(title: "Sorry!", message: "Please grant location permission from settings ")
            return
        }
        guard let nearestDriver = getClosestDriver(drivers: drivers, closestToLocation: location) else {
            showAlert(title: "Oops..sorry!", message: "there is no drivers near you right now, please try again later")
            return
        }
        showAlert(title: "Got It!", message: "there is a driver near you .. \(nearestDriver)")
    }
    
    // not used
    @objc func hideKeyboard(){
        view.endEditing(true)
    }
}

    //MARK:- Extensions

extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        userCurrentLocation = locations.first
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            updateMapView(with: manager.location!.coordinate)
            listLikelyPlaces()
        }
    }
}

extension ViewController :UITextFieldDelegate {
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        menuBtn.isSelected = true
        locationsTV.isHidden = false
        
        if textField == destinationTF {
            isDestinationSearchActive = true
            setupPlacesTableView()
            locationsTV.reloadData()
        }
        
        if textField == locationTF {
            isDestinationSearchActive = false
            locationsTV.reloadData()
        }
    }
    
}
    //MARK: TV Extensions
extension ViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedLocation = locations[indexPath.row]
        updateMapView(with: selectedLocation.coordinate)
        self.selectedSourceLocation = selectedLocation
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension ViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isDestinationSearchActive ? searchedDestinations.count : locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell",for: indexPath)
        if isDestinationSearchActive {
            cell.textLabel?.text = searchedDestinations[indexPath.row].name
        } else {
            cell.textLabel?.text = locations[indexPath.row].name
        }
        return cell
    }
    
}

extension ViewController : GMSAutocompleteTableDataSourceDelegate {
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didAutocompleteWith place: GMSPlace) {
        
    }
    
    func tableDataSource(_ tableDataSource: GMSAutocompleteTableDataSource, didFailAutocompleteWithError error: Error) {
        print("autocomplete error",error)
    }
    
    
}
