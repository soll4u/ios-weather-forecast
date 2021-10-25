//
//  LocationManager.swift
//  WeatherForecast
//
//  Created by Soll on 2021/10/08.
//

import Foundation
import CoreLocation

final class LocationManager: NSObject, CLLocationManagerDelegate {
    
    private let manager = CLLocationManager()
    private var completion: ((CLLocation) -> Void)?
    
    override init() {
        super.init()
        
        manager.requestWhenInUseAuthorization()
        manager.delegate = self
    }
    
    func getUserLocation(completion: @escaping (CLLocation) -> Void) {
        self.completion = completion
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else {
            return
        }
        completion?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .denied:
            print("권한 요청 거부됨")
            // TODO: - Alert + Error 처리
            return
        case .restricted:
            print("권한이 제한됨")
        case .notDetermined:
            print("권한 요청 되지 않음")
            manager.requestWhenInUseAuthorization()
            manager.requestLocation()
            return
        case .authorizedAlways, .authorizedWhenInUse:
            print("권한 있음")
            guard let lastLocation = self.manager.location else {
                return
            }
            completion?(lastLocation)
        @unknown default:
            break
        }
    }
}

extension LocationManager {
    
    func lookUpCurrentPlacemark(completionHandler: @escaping (CLPlacemark) -> Void) {
        guard let lastLocation = self.manager.location else {
            return
        }
        
        let geocoder = CLGeocoder()
        let locale = Locale(identifier: "Ko-kr")
        
        geocoder.reverseGeocodeLocation(lastLocation,
                                        preferredLocale: locale) { (placemarks, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            if let firstLocation = placemarks?.first {
                completionHandler(firstLocation)
            }
        }
    }
}
