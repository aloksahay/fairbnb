import Foundation
import CoreLocation
import Combine

class LocationService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    
    @Published var currentLocation: CLLocation?
    @Published var approximateLocation: ApproximateLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLocationEnabled = false
    @Published var locationError: LocationError?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            // Guide user to settings
            locationError = .permissionDenied
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            locationError = .unknown
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            locationError = .permissionDenied
            return
        }
        
        locationManager.startUpdatingLocation()
        isLocationEnabled = true
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
        isLocationEnabled = false
    }
    
    func getCurrentLocation() async throws -> CLLocation {
        guard let location = currentLocation else {
            throw LocationError.locationNotAvailable
        }
        
        // Ensure location is recent (within 5 minutes)
        let fiveMinutesAgo = Date().addingTimeInterval(-300)
        guard location.timestamp > fiveMinutesAgo else {
            throw LocationError.locationTooOld
        }
        
        return location
    }
    
    func getApproximateLocation(for coordinate: CLLocationCoordinate2D) async throws -> ApproximateLocation {
        return try await withCheckedThrowingContinuation { continuation in
            geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: LocationError.geocodingFailed(error))
                    return
                }
                
                guard let placemark = placemarks?.first else {
                    continuation.resume(throwing: LocationError.geocodingFailed(nil))
                    return
                }
                
                let cityName = placemark.locality ?? placemark.administrativeArea ?? ""
                let countryName = placemark.country ?? ""
                
                let approximateLocation = ApproximateLocation(
                    from: coordinate,
                    cityName: cityName,
                    countryName: countryName
                )
                
                continuation.resume(returning: approximateLocation)
            }
        }
    }
    
    func createLocationProofInput(
        actualLocation: CLLocationCoordinate2D,
        approximateCenter: CLLocationCoordinate2D,
        radiusKm: Double
    ) -> ZKProofInput {
        return ZKProofInput(
            latitude: actualLocation.latitude,
            longitude: actualLocation.longitude,
            centerLatitude: approximateCenter.latitude,
            centerLongitude: approximateCenter.longitude,
            radiusKm: radiusKm,
            timestamp: Int64(Date().timeIntervalSince1970)
        )
    }
    
    func validateLocationWithinRadius(
        actualLocation: CLLocationCoordinate2D,
        center: CLLocationCoordinate2D,
        radiusKm: Double
    ) -> Bool {
        return actualLocation.isWithinRadius(radiusKm, of: center)
    }
    
    func suggestApproximateCenter(
        for actualLocation: CLLocationCoordinate2D,
        radiusKm: Double
    ) -> CLLocationCoordinate2D {
        // Add some random offset within the radius to obscure exact location
        let maxOffset = radiusKm * 0.5 // Use half the radius for offset
        let randomLatOffset = Double.random(in: -maxOffset...maxOffset) / 111.0 // ~111km per degree
        let randomLonOffset = Double.random(in: -maxOffset...maxOffset) / (111.0 * cos(actualLocation.latitude * .pi / 180))
        
        return CLLocationCoordinate2D(
            latitude: actualLocation.latitude + randomLatOffset,
            longitude: actualLocation.longitude + randomLonOffset
        )
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        locationError = nil
        
        // Update approximate location
        Task {
            do {
                let approximate = try await getApproximateLocation(for: location.coordinate)
                await MainActor.run {
                    self.approximateLocation = approximate
                }
            } catch {
                await MainActor.run {
                    self.locationError = error as? LocationError ?? .unknown
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = .locationUpdateFailed(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
            locationError = .permissionDenied
        case .notDetermined:
            break
        @unknown default:
            locationError = .unknown
        }
    }
}

// MARK: - LocationError
enum LocationError: Error, LocalizedError {
    case permissionDenied
    case locationNotAvailable
    case locationTooOld
    case locationUpdateFailed(Error)
    case geocodingFailed(Error?)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location access in Settings."
        case .locationNotAvailable:
            return "Current location is not available. Please try again."
        case .locationTooOld:
            return "Location data is too old. Please try again."
        case .locationUpdateFailed(let error):
            return "Failed to update location: \(error.localizedDescription)"
        case .geocodingFailed(let error):
            return "Failed to get location details: \(error?.localizedDescription ?? "Unknown error")"
        case .unknown:
            return "An unknown location error occurred."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .permissionDenied:
            return "Go to Settings > Privacy & Security > Location Services to enable location access."
        case .locationNotAvailable, .locationTooOld:
            return "Make sure you're in an area with good GPS reception and try again."
        case .locationUpdateFailed, .geocodingFailed:
            return "Check your internet connection and try again."
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}

// MARK: - Location Privacy Utilities
extension LocationService {
    static func formatDistance(_ distanceKm: Double) -> String {
        if distanceKm < 1.0 {
            return "\(Int(distanceKm * 1000))m"
        } else {
            return String(format: "%.1fkm", distanceKm)
        }
    }
    
    static func formatCoordinate(_ coordinate: Double, isLatitude: Bool) -> String {
        let direction = isLatitude ? 
            (coordinate >= 0 ? "N" : "S") : 
            (coordinate >= 0 ? "E" : "W")
        return String(format: "%.6f°%@", abs(coordinate), direction)
    }
    
    static func formatApproximateCoordinate(_ coordinate: Double) -> String {
        // Show only 2 decimal places for privacy
        return String(format: "%.2f°", coordinate)
    }
} 