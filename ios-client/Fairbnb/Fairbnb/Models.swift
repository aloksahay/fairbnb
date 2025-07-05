import Foundation
import CoreLocation

// MARK: - Location Privacy Models
struct LocationProof: Identifiable, Codable {
    let id: String
    let proof: String // ZK proof that location is within radius
    let publicSignals: [String] // Public signals from the proof
    let radiusKm: Double // Radius in kilometers
    let centerPoint: ApproximateLocation // Approximate center point (not exact)
    let timestamp: Date
    let isVerified: Bool
    
    init(id: String = UUID().uuidString, proof: String, publicSignals: [String], radiusKm: Double, centerPoint: ApproximateLocation, timestamp: Date = Date(), isVerified: Bool = false) {
        self.id = id
        self.proof = proof
        self.publicSignals = publicSignals
        self.radiusKm = radiusKm
        self.centerPoint = centerPoint
        self.timestamp = timestamp
        self.isVerified = isVerified
    }
}

struct ApproximateLocation: Codable {
    let latitude: Double // Rounded to ~1km precision
    let longitude: Double // Rounded to ~1km precision
    let cityName: String
    let countryName: String
    
    // Create approximate location from exact coordinates
    init(from coordinate: CLLocationCoordinate2D, cityName: String = "", countryName: String = "") {
        // Round to 2 decimal places (~1km precision)
        self.latitude = round(coordinate.latitude * 100) / 100
        self.longitude = round(coordinate.longitude * 100) / 100
        self.cityName = cityName
        self.countryName = countryName
    }
    
    init(latitude: Double, longitude: Double, cityName: String = "", countryName: String = "") {
        self.latitude = round(latitude * 100) / 100
        self.longitude = round(longitude * 100) / 100
        self.cityName = cityName
        self.countryName = countryName
    }
}

// MARK: - Property Models
struct Property: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let type: PropertyType
    let pricePerNight: Double
    let maxGuests: Int
    let bedrooms: Int
    let bathrooms: Int
    let locationProof: LocationProof // ZK proof of location
    let images: [PropertyImage]
    let amenities: [String]
    let hostId: String
    let rating: Double
    let reviewCount: Int
    let isAvailable: Bool
    let createdAt: Date
    let updatedAt: Date
    
    // Computed property for display location
    var displayLocation: String {
        if !locationProof.centerPoint.cityName.isEmpty {
            return locationProof.centerPoint.cityName
        }
        return "Within \(Int(locationProof.radiusKm))km radius"
    }
}

struct PropertyImage: Identifiable, Codable {
    let id: String
    let imageData: Data? // For local storage
    let imageURL: String? // For remote storage
    let locationProof: LocationProof? // ZK proof that image was taken at claimed location
    let caption: String
    let isPrimary: Bool
    let timestamp: Date
    
    init(id: String = UUID().uuidString, imageData: Data? = nil, imageURL: String? = nil, locationProof: LocationProof? = nil, caption: String = "", isPrimary: Bool = false, timestamp: Date = Date()) {
        self.id = id
        self.imageData = imageData
        self.imageURL = imageURL
        self.locationProof = locationProof
        self.caption = caption
        self.isPrimary = isPrimary
        self.timestamp = timestamp
    }
}

enum PropertyType: String, Codable, CaseIterable {
    case apartment = "Apartment"
    case house = "House"
    case villa = "Villa"
    case condo = "Condo"
    case room = "Room"
    case studio = "Studio"
    
    var icon: String {
        switch self {
        case .apartment: return "building.2"
        case .house: return "house"
        case .villa: return "house.lodge"
        case .condo: return "building"
        case .room: return "bed.double"
        case .studio: return "rectangle.split.3x1"
        }
    }
}

// MARK: - ZK Proof Models
struct ZKProofInput: Codable {
    let latitude: Double
    let longitude: Double
    let centerLatitude: Double
    let centerLongitude: Double
    let radiusKm: Double
    let timestamp: Int64
    
    // Convert to the format expected by ZKMoPro
    func toZKInputs() -> [String: [String]] {
        return [
            "lat": [String(Int(latitude * 1000000))], // Convert to integer with 6 decimal precision
            "lon": [String(Int(longitude * 1000000))],
            "center_lat": [String(Int(centerLatitude * 1000000))],
            "center_lon": [String(Int(centerLongitude * 1000000))],
            "radius_km": [String(Int(radiusKm * 1000))], // Convert to meters
            "timestamp": [String(timestamp)]
        ]
    }
}

struct ZKProofResult: Codable {
    let proof: String
    let publicSignals: [String]
    let isValid: Bool
    let error: String?
    
    init(proof: String, publicSignals: [String], isValid: Bool = true, error: String? = nil) {
        self.proof = proof
        self.publicSignals = publicSignals
        self.isValid = isValid
        self.error = error
    }
}

// MARK: - User Models
struct User: Identifiable, Codable {
    let id: String
    let name: String
    let email: String
    let profileImageURL: String?
    let isHost: Bool
    let rating: Double
    let reviewCount: Int
    let joinedDate: Date
    let walletAddress: String?
    let verificationStatus: VerificationStatus
    let locationPrivacySettings: LocationPrivacySettings
}

struct LocationPrivacySettings: Codable {
    var defaultRadiusKm: Double = 1.0 // Default 1km radius
    var allowExactLocation: Bool = false
    var requireLocationProof: Bool = true
    var maxRadiusKm: Double = 5.0
    
    var radiusOptions: [Double] {
        return [0.5, 1.0, 2.0, 3.0, 5.0]
    }
}

enum VerificationStatus: String, Codable, CaseIterable {
    case unverified = "unverified"
    case pending = "pending"
    case verified = "verified"
    case locationVerified = "location_verified"
}

// MARK: - Booking Models
struct Booking: Identifiable, Codable {
    let id: String
    let propertyId: String
    let guestId: String
    let hostId: String
    let checkInDate: Date
    let checkOutDate: Date
    let guests: Int
    let totalPrice: Double
    let status: BookingStatus
    let paymentMethod: PaymentMethod
    let locationProofVerified: Bool // Whether the location proof was verified
    let createdAt: Date
    let updatedAt: Date
}

enum BookingStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case confirmed = "confirmed"
    case checkedIn = "checked_in"
    case checkedOut = "checked_out"
    case cancelled = "cancelled"
    case completed = "completed"
}

enum PaymentMethod: String, Codable, CaseIterable {
    case bitcoin = "bitcoin"
    case ethereum = "ethereum"
    case creditCard = "credit_card"
}

// MARK: - Search Models
struct SearchFilters: Codable {
    var approximateLocation: ApproximateLocation?
    var searchRadiusKm: Double = 10.0
    var checkInDate: Date = Date()
    var checkOutDate: Date = Date().addingTimeInterval(86400)
    var guests: Int = 1
    var propertyTypes: Set<PropertyType> = []
    var priceRange: ClosedRange<Double> = 0...1000
    var amenities: Set<String> = []
    var minRating: Double = 0
    var requireLocationProof: Bool = true
}

// MARK: - API Response Models
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T?
    let message: String?
    let error: String?
}

struct PaginatedResponse<T: Codable>: Codable {
    let items: [T]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let hasMore: Bool
}

// MARK: - Location Utilities
extension CLLocationCoordinate2D {
    // Calculate distance between two coordinates in kilometers
    func distance(to coordinate: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let location2 = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location1.distance(from: location2) / 1000.0 // Convert to km
    }
    
    // Check if coordinate is within radius of another coordinate
    func isWithinRadius(_ radiusKm: Double, of center: CLLocationCoordinate2D) -> Bool {
        return distance(to: center) <= radiusKm
    }
} 