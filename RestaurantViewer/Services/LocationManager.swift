import Foundation
import CoreLocation

/// One-shot source of the device coordinate. Protocol-based so the view model
/// can be driven by a stub in tests (and so the app can inject a fixed
/// coordinate under UI tests without triggering a real permission prompt).
protocol LocationProviding {
    func currentCoordinate() async throws -> CLLocationCoordinate2D
}

/// Wraps CLLocationManager behind an async API.
///
/// Trade-off: a real production manager would publish location updates
/// continuously (for distance recalc, etc.). For this take-home we only
/// need the initial coordinate, so we resolve a single continuation
/// when the first authorized fix arrives.
final class LocationManager: NSObject, CLLocationManagerDelegate, LocationProviding {

    enum LocationError: Error, LocalizedError {
        case denied
        case restricted
        case unknown

        var errorDescription: String? {
            switch self {
            case .denied:
                return "Location access denied. Showing restaurants near a default location."
            case .restricted:
                return "Location services are restricted on this device."
            case .unknown:
                return "Could not determine your location."
            }
        }
    }

    /// Default fallback coordinate (NYC). Used when permission is denied so
    /// the demo still works for reviewers who skip the prompt.
    static let fallbackCoordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)

    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    /// Returns a one-shot coordinate. If permission is denied, throws
    /// LocationError.denied so the caller can decide to use a fallback.
    func currentCoordinate() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse:
                manager.requestLocation()
            case .denied:
                resolve(error: LocationError.denied)
            case .restricted:
                resolve(error: LocationError.restricted)
            @unknown default:
                resolve(error: LocationError.unknown)
            }
        }
    }

    // MARK: - CLLocationManagerDelegate

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            manager.requestLocation()
        case .denied:
            resolve(error: LocationError.denied)
        case .restricted:
            resolve(error: LocationError.restricted)
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coord = locations.first?.coordinate else {
            resolve(error: LocationError.unknown)
            return
        }
        resolve(value: coord)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        resolve(error: error)
    }

    // MARK: - Continuation helpers

    private func resolve(value: CLLocationCoordinate2D) {
        continuation?.resume(returning: value)
        continuation = nil
    }

    private func resolve(error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
