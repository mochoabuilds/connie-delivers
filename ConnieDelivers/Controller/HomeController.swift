//
//  HomeController.swift
//  ConnieDelivers
//
//  Created by M. Ochoa on 1/29/21.
//

import UIKit
import Firebase
import MapKit

private let reuseIdentifer = "LocationCell"
private let annotationIdentifier = "DriverAnnotation"

class HomeController: UIViewController {
    
    // MARK: - Properties
    
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    
    private let inputActivationView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    private var searchResults = [MKPlacemark]()
    
    private var user: User? {
        didSet { locationInputView.user = user }
    }
    
    private final let locationInputViewHeight: CGFloat  = 200
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
        enableLocationServices()
//        signOut()
    }
    
    // MARK: - API
    
    func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        Service.shared.fetchUserData(uid: currentUid) { user in
            self.user = user
        }
    }
    
    // display driver on map
    func fetchDrivers() {
        guard let location = locationManager?.location else { return }
        Service.shared.fetchDriver(location: location) { (driver) in
            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            
            // determining if driver is already visble
            var driverIsVisble: Bool {
                return self.mapView.annotations.contains { annotation -> Bool in
                    guard let driverAnno = annotation as? DriverAnnotation else { return false }
                    
                    if driverAnno.uid == driver.uid {
                        driverAnno.updateAnnotationPosition(withCoordinate: coordinate)
                        return true
                    }
                    return false
                }
            }
            // adding driver to map if not visble
            if !driverIsVisble {
                self.mapView.addAnnotation(annotation)
            }
        }
    }

    // check if guest logged in
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                self.present(nav, animated: true, completion: nil)
            }
        } else {
           configure()
        }
    }
        // sign out
        func signOut() {
            do {
                try Auth.auth().signOut()
                DispatchQueue.main.async {
                    let nav = UINavigationController(rootViewController: LoginController())
                    self.present(nav, animated: true, completion: nil)
                }
            } catch {
                print("FIX ME: Error signing out")
            }
        }
    
        // MARK: - Helper Functions
    
        func configure() {
            configureUI()
            fetchUserData()
            fetchDrivers()
        }
    
        func configureUI() {
            configureMapView()
            
            view.addSubview(inputActivationView)
            inputActivationView.centerX(inView: view)
            inputActivationView.setDimensions(height: 50, width: view.frame.width - 64)
            inputActivationView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
            inputActivationView.alpha = 0
            inputActivationView.delegate = self
            
            UIView.animate(withDuration: 2) {
                self.inputActivationView.alpha = 1
            }
            
            configureTableView()
        }

        func configureMapView() {
            view.addSubview(mapView)
            mapView.frame = view.frame
            
            mapView.showsUserLocation = true
            mapView.userTrackingMode = .follow
            mapView.delegate = self
        }
    
        func configureLocationInputView() {
            locationInputView.delegate = self
            view.addSubview(locationInputView)
            locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor,
                                 right: view.rightAnchor, height: 200)
            locationInputView.alpha = 0
        
        // dynamic animations
        UIView.animate(withDuration: 0.5, animations: {
            self.locationInputView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.frame.origin.y = self.locationInputViewHeight
            })
        }
    }
    
    func configureTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.register(LocationCell.self, forCellReuseIdentifier: reuseIdentifer)
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView()
        
        let height = view.frame.height - locationInputViewHeight
        tableView.frame = CGRect(x: 0, y: view.frame.height,
                                 width: view.frame.width, height: height)
        
        view.addSubview(tableView)
    }
    
    func dismissLocationView(completion: ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.4, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            // Lightens Computational Load
            self.locationInputView.removeFromSuperview()
            
            UIView.animate(withDuration: 0.3, animations: {
                self.inputActivationView.alpha = 1
            })
        }, completion: completion)
    }
}

// MARK: - Map Helper Functions

private extension HomeController {
    func searchBy(naturalLanguageQuery: String, completion: @escaping([MKPlacemark]) -> Void) {
        var results =  [MKPlacemark]()
        
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response else { return }
            
            response.mapItems.forEach({ item in
                results.append(item.placemark)
            })
            completion(results)
        }
    }
}


// MARK: - MKMapViewDelegate

extension HomeController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier )
            view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
            return view
        }
        return nil
    }
    
}

// MARK: - LocationServices

extension HomeController {
    func enableLocationServices() {
        // FIX ME: authorizationStatus()' was deprecated in iOS 14.0
        switch CLLocationManager.authorizationStatus(){
        case .notDetermined:
            print("FIX ME: Not determined...")
            locationManager?.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("FIX ME: Auth always...")
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("FIX ME: Auth when in use...")
            locationManager?.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
}

// MARK: - LocationInputActivationViewDelegate

extension HomeController: LocationInputActivationViewDelegate {
    func presentLocationInputView() {
        
        configureLocationInputView()
        inputActivationView.alpha = 0
        configureLocationInputView()
    }
}

// MARK: - LocationInputViewDelegate

extension HomeController: LocationInputViewDelegate {
    func exectureSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { (results) in
            self.searchResults = results
            self.tableView.reloadData()
        }
    }
    
    func dismissLocationInputView() {
       dismissLocationView()
    }
}

// MARK: - UITableViewDelegate/DataSource

extension HomeController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Test"
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // If Section Equal to Zero Then Show 2, If Not Show 5
        return section == 0 ? 2 : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifer, for: indexPath) as!
            LocationCell
        
        if indexPath.section == 1 {
            cell.placemark = searchResults[indexPath.row]
        }
    
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlacemark = searchResults[indexPath.row]
        dismissLocationView { _ in
            let annotation = MKPointAnnotation()
            annotation.coordinate = selectedPlacemark.coordinate
            self.mapView.addAnnotation(annotation)
            self.mapView.selectAnnotation(annotation, animated: true)
        }
    }
}
