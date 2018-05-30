//
//  ViewController.swift
//  CercaPiuNavigazione
//
//  Created by Francesco Castelluccio on 17/12/17.
//  Copyright © 2017 Francesco Castelluccio. All rights reserved.
//

import UIKit
import AudioToolbox
import MapKit
import CoreLocation
import AddressBookUI
import AVFoundation
import WatchConnectivity

func delayWithSeconds(_ seconds: Double, completion: @escaping () -> ()) {
    DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        completion()
    }
}

var thisView = ViewController()

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, WCSessionDelegate, MKLocalSearchCompleterDelegate, UITableViewDataSource, UITableViewDelegate {
   
    public var searchCompleter = MKLocalSearchCompleter()
    public var searchResults = [MKLocalSearchCompletion]()
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var senderView: UIView!
    @IBOutlet weak var notificLabel: UILabel!
    
    let locationManager = CLLocationManager()
    var currentCoordinate: CLLocationCoordinate2D!
    var totalMeter = 0.0
    
    var steps = [MKRouteStep]()
    let speechSynthesizer = AVSpeechSynthesizer()
    
    var stepCounter = 0
    
    @IBOutlet weak var directionsLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchResultsTableView: UITableView!
    var count: Int = 0
    // var coordinate: Array[]
    var artworks: [Artwork] = []
    var countAllert = 0
    var artworkCoordinateUsed: [CLLocationCoordinate2D] = []
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        
        //copy received message
        var receivedMessage: [String: Any] = message
        
        //for dispatching messages faster
        DispatchQueue.main.async {
            
            //start session if it has been started from watch and it's not already started
            if let started = receivedMessage["startAction"] {
                if (started as? Bool)! && (self.sessionActive == false) {
                    self.sessionActive = true
                    //self.startStopButton.setTitle("Stop", for: .normal)
                    //self.startStopButton.backgroundColor = UIColor.red
                }
            }
            
            //stop session if it has been stopped from watch and it's not already stopped
            if let stopped = receivedMessage["stopAction"] {
                if (stopped as? Bool)! && (self.sessionActive == true) {
                    self.sessionActive = false
//                    self.startStopButton.setTitle("Start", for: .normal)
//                    self.startStopButton.backgroundColor = UIColor.green
                }
            }
            
            
            //display error type if there is any
            if let warning = receivedMessage["warning"] {
//                self.warningLabel.text = "Received warning n. \(warning)"
//                self.warningNumber = warning as! Int
            }
        }
    }
    
    //send message to watch function
    func sendMessageToWatch(message: [String: Any]) {
        if (WCSession.default.isReachable) {
            WCSession.default.sendMessage(message, replyHandler: nil, errorHandler: nil)
        }
    }
    
    
    
    //state of the session
    var sessionActive = false
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        

    }
    
    override func viewWillAppear(_ animated: Bool) {
        thisView = self
        directionsLabel.numberOfLines = 4
        searchCompleter.delegate = self
        searchBar.enablesReturnKeyAutomatically = true
        locationManager.requestAlwaysAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
        tableView.delegate = self
        tableView.isHidden = true
        //        sendButton.isHidden = true
        senderView.isHidden = true
        self.mapView.register(ArtworkMarkerView.self,
                              forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        callAnnotation()
        //open communication session with watch
        if (WCSession.isSupported()) {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.sender = 0
        
    }
    
    @IBAction func testButton(_ sender: Any) {
        
    }
    
    func hideContainerView() {
        self.senderView.isHidden = true

    }
    
    func hideContainerViewWithAnn(Artwork: Artwork) {
        self.senderView.isHidden = true
        self.mapView.addAnnotation(Artwork)
    }
    
    @IBAction func sendAnnotation(_ sender: Any) {
        senderView.isHidden = false
        //setButton.isHidden = true
        sendButton.isHidden = true
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.userLat = self.currentCoordinate.latitude
        appDelegate.userLog = self.currentCoordinate.longitude
        appDelegate.sendType = 0
    }
    

    //parte della navigazione
    
//    Questa funzione ti da le indicazioni
    func getDirections(to destination: MKMapItem) {
        let sourcePlacemark = MKPlacemark(coordinate: currentCoordinate)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let directionsRequest = MKDirectionsRequest()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destination
        directionsRequest.transportType = .walking
        
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { (response, _) in
            guard let response = response else { return }
            guard let primaryRoute = response.routes.first else { return }
            
            self.mapView.add(primaryRoute.polyline)
            
            self.locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })
            
            self.steps = primaryRoute.steps
            for i in 0 ..< primaryRoute.steps.count {
                let step = primaryRoute.steps[i]
                print(step.instructions)
                print(step.distance)
//              In totalMeter c'è la somma totale dei metri
                self.totalMeter += Double(step.distance)

                let region = CLCircularRegion(center: step.polyline.coordinate,
                                              radius: 20,
                                              identifier: "\(i)")
                self.locationManager.startMonitoring(for: region)
                let circle = MKCircle(center: region.center, radius: region.radius)
                self.mapView.add(circle)
            }
            
            //Print delle indicazioni nella label
            let initialMessage = "In \(self.steps[0].distance) meters, \(self.steps[0].instructions) then in \(self.steps[1].distance) meters, \(self.steps[1].instructions)."
            self.directionsLabel.text = initialMessage
            let speechUtterance = AVSpeechUtterance(string: initialMessage)
            self.speechSynthesizer.speak(speechUtterance)
            self.stepCounter += 1
        }
    }
    
    //funzione per cancellare annotation
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        let location = view.annotation as! Artwork
        
        let alert = UIAlertController(title: "Are You sure?", message: "Message", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {
            action in
            let artToDel = AnnotationWrited(title: "Title", location: "loc", discipline: "disc", latitudine: String(location.coordinate.latitude), longitude: String(location.coordinate.longitude))
            self.cancAnnotation(ann: artToDel) { (error) in
                if let error = error {
                    fatalError(error.localizedDescription)
                }
            }
            self.mapView.removeAnnotation(location)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil ))
        self.present(alert, animated: true, completion: nil)
    }
    
    //funzione per caricare le annotation
    func callAnnotation() {
        let jsonUrl = "https://noemisolution.it/academy/annotationJson.json"
        
        
        guard let url = URL(string: jsonUrl ) else
        { return }
        
        var myrequest: URLRequest = URLRequest(url: url)
        let mysession = URLSession.shared
        myrequest.cachePolicy = URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData
        mysession.dataTask(with: myrequest) { data, response, error in
            guard let data = data else {return}
            
            do {
                let annotations = try JSONDecoder().decode([AnnotationReaded].self, from: data)
                print(annotations)
                
                for annotation in annotations {
                    let artwork = Artwork(title: annotation.TITLE, locationName: annotation.LOCATION, discipline: annotation.DISCIPLINE, lat: annotation.LATITUDINE, log: annotation.LONGITUDINE)
                    self.mapView.addAnnotation(artwork)
                    self.artworks.append(artwork)
                }
            }
            catch let jsonErr {
                print("Error", jsonErr)
            }
            
            }.resume()
        
    }
    
    
    func cancAnnotation(ann: AnnotationWrited, completion:((Error?) -> Void)?) {
        let postUrl = "https://noemisolution.it/academy/annotationCanc.php"
        guard let url = URL(string: postUrl ) else { fatalError("Could not create URL") }
        
        // Specify this request as being a POST method
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        // Make sure that we include headers specifying that our request's HTTP body
        // will be JSON encoded
        var headers = request.allHTTPHeaderFields ?? [:]
        headers["Content-Type"] = "application/json"
        request.allHTTPHeaderFields = headers
        
        // Now let's encode out Post struct into JSON data...
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(ann)
            // ... and set our request's HTTP body
            request.httpBody = jsonData
            print("jsonData: ", String(data: request.httpBody!, encoding: .utf8) ?? "no body data")
        } catch {
            completion?(error)
        }
        
        // Create and run a URLSession data task with our JSON encoded POST request
        let config = URLSessionConfiguration.default
        let session = URLSession(configuration: config)
        let task = session.dataTask(with: request) { (responseData, response, responseError) in
            guard responseError == nil else {
                completion?(responseError!)
                return
            }
            
            // APIs usually respond with the data you just sent in your POST request
            if let data = responseData, let utf8Representation = String(data: data, encoding: .utf8) {
                print(request)
                print("response: ", utf8Representation)
            } else {
                print("no readable data received in response")
            }
        }
        
        task.resume()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        guard let currentLocation = locations.first else { return }
        currentCoordinate = currentLocation.coordinate
        mapView.userTrackingMode = .followWithHeading
    }
    
    //parte della ricerca
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        print("ENTERED")
        stepCounter += 1
        if stepCounter < steps.count {
            let currentStep = steps[stepCounter]
            let message = "In \(currentStep.distance) meters, \(currentStep.instructions)"
            directionsLabel.text = message
            let speechUtterance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtterance)
        } else {
            let message = "Arrived at destination"
            directionsLabel.text = message
            let speechUtterance = AVSpeechUtterance(string: message)
            speechSynthesizer.speak(speechUtterance)
            stepCounter = 0
            locationManager.monitoredRegions.forEach({ self.locationManager.stopMonitoring(for: $0) })
            
        }
    }
    
    //print posizione utente
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        self.currentCoordinate = userLocation.coordinate
        
        //print("posizione aggiornata - lat: \(userLocation.coordinate.latitude) long: \(userLocation.coordinate.longitude)")
        let span = MKCoordinateSpanMake(0.001, 0.001)
        let region = MKCoordinateRegion(center: userLocation.coordinate, span: span)
        
        for artwork in self.artworks {
            // print("Qua va")
            let artworkTemp = CLLocation(latitude: artwork.coordinate.latitude, longitude: artwork.coordinate.longitude)
            let userCoordinate = CLLocation(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
            
            if (userCoordinate.distance(from: artworkTemp) < 50 ) {
                
                if artworkCoordinateUsed.isEmpty {
                    print("Alert")
                    AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.sendType = 1
                    print("send type: ")
                    print(appDelegate.sendType)
                    let errorString = artwork.discipline
                    
                    
                    var errorNumber = 0
                    
                    switch errorString  {
                        
                    case "Hole":
                        errorNumber = 1
                    case "Stop":
                        errorNumber = 2
                    case "Accident":
                        errorNumber = 3
                    case "Work":
                        errorNumber = 4
                    default:
                        print("")
                        
                    }
                    delayWithSeconds(2) {
                        self.notificLabel.isHidden = false
                        appDelegate.errorString = errorString
                        print(errorString)
        
                    }
                    sendMessageToWatch(message: ["warning" : errorNumber])
                    artworkCoordinateUsed.append(artworkTemp.coordinate)
                    
                    delayWithSeconds(3) {
                        self.hideContainerView()
                    }
                    
                    
                } else {
                    for coordinateToCheck in artworkCoordinateUsed {
                        if(coordinateToCheck.latitude == userCoordinate.coordinate.latitude && coordinateToCheck.longitude == userCoordinate.coordinate.longitude) {
                            print("Alert")
                            let appDelegate = UIApplication.shared.delegate as! AppDelegate
                            appDelegate.sendType = 1
                            senderView.isHidden = false
                            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                        } else {
                            
                            artworkCoordinateUsed.append(userCoordinate.coordinate)
                            return
                        }
                    }
                }
                
            }
        }
        
        //setButton.isHidden = false
        //sendButton.isHidden = false
        
        if(count == 0){
            print(count)
            count = count + 1
            mapView.setRegion(region, animated: true)
            
        }
    }
    
    //Rendering del percorso sulla mappa
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 10
            return renderer
        }
        if overlay is MKCircle {
            let renderer = MKCircleRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.fillColor = .red
            renderer.alpha = 0.5
            return renderer
        }
        searchBar.isHidden = true
        return MKOverlayRenderer()
    }
    //funzione della searchBar
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        tableView.isHidden = false
        searchCompleter.queryFragment = searchText
        
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        searchResultsTableView.reloadData()
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        // handle error
    }
    
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let searchResult = searchResults[indexPath.row]
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = searchResult.title
        cell.detailTextLabel?.text = searchResult.subtitle
        return cell
    }

    
    // Risultati della ricerca appaiono sulla tableview e cambiano dinamicamente
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let completion = searchResults[indexPath.row]
        let searchRequest = MKLocalSearchRequest(completion: completion)
//        let search = MKLocalSearch(request: searchRequest)
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.searchRequest = completion
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let secondVC = storyboard.instantiateViewController(withIdentifier: "DoubleViewController") as! DoubleViewController
        self.show(secondVC, sender: self)
//
//       self.present(vc, animated: true, completion: nil)
        
    }
}

extension UIViewController
{
    func hideKeyboard()
    {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(
            target: self,
         action: #selector(UIViewController.dismissKeyboard))
        
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard()
    {
        view.endEditing(true)
    }
}


