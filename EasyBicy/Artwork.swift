//
//  Artwork.swift
//  Easy Bicy
//
//  Created by Gennaro Amura on 17/12/17.
//  Copyright © 2017 Gennaro Amura. All rights reserved.
//

import Foundation
import Contacts
import MapKit

class Artwork: NSObject, MKAnnotation {
    let title: String?
    let locationName: String
    let discipline: String
    let coordinate: CLLocationCoordinate2D

    
    init(title: String, locationName: String, discipline: String, coordinate: CLLocationCoordinate2D) {
        self.title = discipline
        self.locationName = locationName
        self.discipline = discipline
        self.coordinate = coordinate
        
        super.init()
    }
    
    init(title: String, locationName: String, discipline: String, lat: String, log: String){
        self.title = discipline
        self.locationName = locationName
        self.discipline = discipline
        coordinate = CLLocationCoordinate2D(latitude: CLLocationDegrees(lat)!, longitude: CLLocationDegrees(log)!)
    }
    
    public var subtitle: String? {
        return locationName
    }
    
    var markerTintColor: UIColor  {
        switch discipline {
        case "Hole":
            return .red
        case "Stop":
            return .cyan
        case "Accident":
            return .blue
        case "Work":
            return .purple
        default:
            return .green
        }
    }
    
    
    var imageName: String? {
        if discipline == "discipline" { return "Flag" }
        return "Flag"
    }
    
    
    func mapItem() -> MKMapItem {
        let addressDict = [CNPostalAddressStreetKey: subtitle!]
        let placemark = MKPlacemark(coordinate: coordinate, addressDictionary: addressDict)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = title
        return mapItem
    }
}

class ArtworkMarkerView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            // 1
            guard let artwork = newValue as? Artwork else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: -5, y: 5)
//            rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            let mapsButton = UIButton(frame: CGRect(origin: CGPoint.zero,
                                                    size: CGSize(width: 30, height: 30)))
            mapsButton.setBackgroundImage(UIImage(named: "Maps-icon"), for: UIControlState())
            rightCalloutAccessoryView = mapsButton
            let detailLabel = UILabel()
            detailLabel.numberOfLines = 0
            detailLabel.font = detailLabel.font.withSize(12)
            detailLabel.text = ""
            detailCalloutAccessoryView = detailLabel
            markerTintColor = artwork.markerTintColor
            //glyphText = String(artwork.discipline.first!)
            if let imageName = artwork.imageName {
                glyphImage = UIImage(named: imageName)
            } else {
                glyphImage = nil
            }
        }
    }
    
}

struct AnnotationWrited : Codable {
    let title: String
    let location: String
    let discipline: String
    let latitudine: String
    let longitude: String
}

struct AnnotationReaded : Decodable {
    let TITLE: String
    let LOCATION: String
    let DISCIPLINE: String
    let LATITUDINE: String
    let LONGITUDINE: String
    
}
