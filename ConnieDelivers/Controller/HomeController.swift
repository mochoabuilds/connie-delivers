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

class HomeController: UIViewController {
    
    // MARK: - Properties
    
    private let mapView = MKMapView()
    private let locationManager = CLLocationManager()
    
    private let inputActivationView = LocationInputActivationView()
    private let locationInputView = LocationInputView()
    private let tableView = UITableView()
    
    private var user: User? {
        didSet { locationInputView.user = user }
    }
    
    private final let locationInputViewHeight: CGFloat  = 200
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkIfUserIsLoggedIn()
        enableLocationServices()
        fetchUserData()
//        signOut()
    }
    
    // MARK: - API
    
    func fetchUserData() {
        Service.shared.fetchUserData { user in
            self.user = user
        }
    }
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                self.present(nav, animated: true, completion: nil)
            }
        } else {
           configureUI()
        }
    }
    
        func signOut() {
            do {
                try Auth.auth().signOut()
            } catch {
                print("FIX ME: Error signing out")
            }
        }
    
        // MARK: - Helper Functions
    
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
    }
    
    func configureLocationInputView() {
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor,
                                 right: view.rightAnchor, height: 200)
        locationInputView.alpha = 0
        
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
}

// MARK: - Location Services

extension HomeController: CLLocationManagerDelegate {
    func enableLocationServices() {
        locationManager.delegate = self
        
        switch CLLocationManager.authorizationStatus(){
        case .notDetermined:
            print("FIX ME: Not determined...")
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            break
        case .authorizedAlways:
            print("FIX ME: Auth always...")
            locationManager.startUpdatingLocation()
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            print("FIX ME: Auth when in use...")
            locationManager.requestAlwaysAuthorization()
        @unknown default:
            break
        }
    }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status:
            CLAuthorizationStatus) {
            
            if status == .authorizedWhenInUse {
                locationManager.requestAlwaysAuthorization()
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
    func dismissLocationInputView() {
        

        UIView.animate(withDuration: 0.3, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
        }) { _ in
            // Lightens Computational Load
            self.locationInputView.removeFromSuperview()
            UIView.animate(withDuration: 0.3, animations: {
                self.inputActivationView.alpha = 1
            })
        }
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
        return section == 0 ? 2 : 5
    }
    
    //
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifer, for: indexPath) as!
            LocationCell
        return cell
    }
}
