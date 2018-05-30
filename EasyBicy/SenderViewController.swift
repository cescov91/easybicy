//
//  SenderViewController.swift
//  Easy Bicy
//
//  Created by Gennaro Amura on 18/12/17.
//  Copyright © 2017 Gennaro Amura. All rights reserved.
//

import UIKit
import MapKit



class SenderViewController: UIViewController {

    var latitudine: CLLocationDegrees = 0.0
    var longitudine: CLLocationDegrees = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    @IBAction func hideItsSelf(_ sender: Any) {
        thisView.hideContainerView()
        thisView.sendButton.isHidden = false
        //thisView.setButton.isHidden = false
    }
    
    
    @IBAction func holeSender(_ sender: Any) {
        print("Hole")
        senderFinal(discipline: "Hole")
    }
    
    @IBAction func stopSender(_ sender: Any) {
        print("Stop")
        senderFinal(discipline: "Stop")
    }
    
    @IBAction func accidentSender(_ sender: Any) {
        print("Accident")
        senderFinal(discipline: "Accident")
    }
    
    @IBAction func workSender(_ sender: Any) {
        print("Work")
        senderFinal(discipline: "Work")
    }
    

    
    func sendAnnotation(ann: AnnotationWrited, completion:((Error?) -> Void)?) {
        let postUrl = "https://noemisolution.it/academy/annotationPost.php"
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
    
    func senderFinal(discipline: String) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        print(appDelegate.userLat)
        print(appDelegate.userLog)
        
        let artwork = AnnotationWrited(title: "Title", location: "Location", discipline: discipline, latitudine: String(appDelegate.userLat), longitude: String(appDelegate.userLog))
        sendAnnotation(ann: artwork) { (error) in
            if let error = error {
                fatalError(error.localizedDescription)
            }
            
        }
        
       let art = Artwork(title: "Title", locationName: "Location", discipline: discipline, lat: String(appDelegate.userLat), log: String(appDelegate.userLog))
        thisView.hideContainerViewWithAnn(Artwork: art)
        
    }

}
