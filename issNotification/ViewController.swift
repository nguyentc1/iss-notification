//
//  ViewController.swift
//  issNotification
//
//  Created by Cuong Nguyen on 2/19/18.
//  Copyright © 2018 Cuong Nguyen. All rights reserved.
//

import UIKit
import CoreLocation


class ViewController: UIViewController,CLLocationManagerDelegate,UITableViewDataSource, UITableViewDelegate{
    @IBOutlet weak var tableView: UITableView!
    
    //json structure as defined in http://open-notify.org/Open-Notify-API/ISS-Pass-Times/
    struct issJsonRequest: Codable{
        let latitude,longitude,altitude,passes,datetime: Double
    }
    struct issPass:Codable{
        let risetime: Double
        let duration: Int
    }
    struct issJson: Codable{
        let message: String
        let request: issJsonRequest
        let response: [issPass]
    }
    //cells are defined as an expected struct
    var cells:[issPass] = []
    //load locationManager
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        //load table,location as self for simplicity
        tableView.delegate = self
        tableView.dataSource = self
        
        //get location authorizations
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        
        // If location services is enabled get the users location
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest // You can change the locaiton accuary here.
            locationManager.startUpdatingLocation()
        }
    }
    
    func callApi(location: CLLocationCoordinate2D){
        //serialization of gps updates probably prefered
        let serialQueue = DispatchQueue(label: "issApiCall")
        serialQueue.sync {
            guard let url = URL(string: "http://api.open-notify.org/iss-pass.json?lat=\(location.latitude)&lon=\(location.longitude)") else {
                return
            }
            let configuration = URLSessionConfiguration.ephemeral
            let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: OperationQueue.main)
            let task = session.dataTask(with: url , completionHandler: { [weak self] (data: Data?, response: URLResponse?, error: Error?) -> Void in
                // Parse the data in the response and use it
                guard let data = data else {return}
                do{
                    //reset cells on each refresh?
                    self?.cells = []
                    let parsedData = try JSONDecoder().decode(issJson.self, from: data)
                    //print(parsedData.response)
                    for pass in parsedData.response {
                        self?.cells.append(pass)
                    }
                    DispatchQueue.main.async {
                        self?.tableView.reloadData()
                    }
                }catch{
                    
                }
            })
            task.resume()
        }
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cells.count
    }
    
    // create a cell for each table view row
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let dateformatter = DateFormatter()
        dateformatter.dateStyle = .medium
        dateformatter.timeStyle = .short
        dateformatter.locale = Locale(identifier: "en_US")
        // create a new cell if needed or reuse an old one
        let cell:UITableViewCell = self.tableView.dequeueReusableCell(withIdentifier: "TextCell") as UITableViewCell!
        
        // set the text from the data model
        if self.cells.count > 0 {
            let date = NSDate(timeIntervalSince1970: self.cells[indexPath.row].risetime)
            let dateText = dateformatter.string(from: date as Date)
            let durationText = String(self.cells[indexPath.row].duration)
            cell.textLabel?.text = "ISS will pass over on " + dateText + " for " + durationText + " seconds."
        }
        return cell
    }
    
    // method to run when table view cell is tapped
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //empty stub, required but not used
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //gets gps of device and sends it to function apiCall
        guard let location: CLLocationCoordinate2D = manager.location?.coordinate else {return}
        callApi(location:location)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

