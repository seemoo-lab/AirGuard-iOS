//
//  MapView.swift
//  AirGuard
//
//  Created by Leon Böttger on 30.05.22.
//

import SwiftUI
import MapKit

/// The identifier for our custom MarkerAnnotationView
let reuseIdentifier = "trackerAnnotation"


/// SwiftUI wrapper for MKMapView
struct MapView: UIViewRepresentable {
    
    /// The annotations (locations) to show on the map
    var annotations: [MapAnnotation]
    
    /// The locations of the tracker, sorted by time. This is used to connect the annotations with lines.
    var connections: [CLLocationCoordinate2D]
    
    /// The count of all connections. This is used to determine if the view should be refreshed.
    @State private var locationsCount = 0
    
    /// Determines if the title labels of the annotations should be shown
    @State var showAnnotationLabels = true
    
    /// Determines if the map has finished loading
    @Binding var mapFinishedLoading: Bool
    
    
    /// Adds the polyline and circle overlays to the given mapview.
    func setUpOverlays(onView: MKMapView) {
        
        /// Add the polyline (connections)
        /// we need to set up all polylines separately. This is due to a glitch which occurs whenever one line within a single polyline is drawn twice
        for index in connections.indices {
            
            /// To not get an out of bounds exception
            if(index != connections.indices.last) {
                
                /// The coordinates to connect.
                let coord1 = connections[index]
                let coord2 = connections[index+1]
                
                let connection = [coord1, coord2]
                
                /// Draw polyline between both coordinates.
                let polyline = MKPolyline(coordinates: connection, count: 2)
                onView.addOverlay(polyline)
                
            }
        }
        
        /// Add the circles. This shows the user that the locations might not be 100% precise.
        for annotation in annotations {
            
            let center = annotation.coordinate
            
            /// The radius is the minimum accuracy. This makes sure that the actual location is somewhere in the circle.
            let circle = MKCircle(center: center, radius: LocationManager.sharedInstance.accuracyLimit)
            onView.addOverlay(circle)
        }
    }
    
    
    /// Creates the `MKMapView`
    func makeUIView(context: Context) -> MKMapView {
        
        /// Set `locationsCount` to initial value.
        DispatchQueue.main.async {
            locationsCount = connections.count
        }
        
        /// Create the new map view.
        let view = MKMapView()
        
        /// Set the delegate
        view.delegate = context.coordinator
        
        /// Move annotations up
        view.layoutMargins.top = -40
        
        /// Add the overlays to the map
        setUpOverlays(onView: view)
        
        /// Add the annotations and put them in focus
        view.showAnnotations(annotations, animated: false)
        
        /// Hide the map - we will show it after it has been loaded
        view.layer.opacity = 0
        
        return view
    }
    
    
    /// Creates the coordinator for `MKMapView`
    func makeCoordinator() -> Coordinator {
        MapView.Coordinator(parent: self)
    }
    
    
    /// Updates the `MKMapView`
    func updateUIView(_ uiView: MKMapView, context: Context) {
        
        /// We received new location data. Otherwise, we do not need to refresh
        if locationsCount != connections.count {
            
            /// Remove all annotations and overlays
            uiView.removeAnnotations(uiView.annotations)
            uiView.removeOverlays(uiView.overlays)
            
            /// Create the new overlays
            setUpOverlays(onView: uiView)
            
            /// Add the annotations and put them in focus
            uiView.showAnnotations(annotations, animated: true)
            
            /// Update `locationsCount`
            DispatchQueue.main.async {
                locationsCount = connections.count
            }
        }
    }
    
    
    /// The coordinator for `MKMapView`
    class Coordinator: NSObject, MKMapViewDelegate {
        
        /// The color for the annotations and overlays
        let primaryColor = UIColor(Color.accentColor)
        
        /// Reference to the MapView.
        var parent: MapView
        
        /// Initialize the coordinator
        init(parent: MapView) {
            
            /// Set the parent
            self.parent = parent
        }
        
        
        /// Creates the view for individual annotations.
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            
            /// Regular/single annotation
            if let annotation = annotation as? MapAnnotation {
                
                /// Create the view for the annotation and set the color
                let view = MarkerAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
                
                view.glyphTintColor = .clear
                view.glyphText = ""
                view.markerTintColor = .clear
                
                view.titleVisibility = parent.showAnnotationLabels ? .adaptive : .hidden

                let size: CGFloat = 20
                let locationdot = UIImage(named: "locationdot")?.resized(to: CGSize(width: size, height: size))
                view.image = locationdot
                view.centerOffset = CGPoint(x: 0, y: 0)
                
                return view
            }
            
            return nil
        }
        
        
        /// Creates the view for overlays.
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            
            /// Creates the view for the polyline.
            if let polyline = overlay as? MKPolyline {
                let lineRenderer = MKPolylineRenderer(polyline: polyline)
                lineRenderer.strokeColor = primaryColor.withAlphaComponent(0.7)
                lineRenderer.lineWidth = 5.0
                lineRenderer.lineCap = .round
                lineRenderer.lineJoin = .round
                
                return lineRenderer
            }
            
            
            /// Creates the view for circles.
            if let circle = overlay as? MKCircle {
                let circleRenderer = MKCircleRenderer(overlay: circle)
                circleRenderer.fillColor = primaryColor.withAlphaComponent(0.2)
                circleRenderer.strokeColor = UIColor.clear
                circleRenderer.lineWidth = 2
                return circleRenderer
            }
            
            /// Fallback - default
            return MKOverlayRenderer(overlay: overlay)
        }
        
        
        /// The map finished loading
        func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
            
            /// Make the map visible
            UIView.animate(withDuration: 0.2) {
                mapView.layer.opacity = 1
            }

            parent.mapFinishedLoading = true
        }
    }
}


/// Disables MKMapKit clustering
final class MarkerAnnotationView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            /// Disables clustering of pins
            displayPriority = MKFeatureDisplayPriority.required
        }
    }
}


/// Class to represent MKAnnotations on the map
class MapAnnotation: NSObject, MKAnnotation {
    
    /// The coordinate of the annotation
    let coordinate: CLLocationCoordinate2D
    
    /// The title of the annotation
    let title: String?
    
    /// The subtitle of the annotation
    let subtitle: String?
    
    /// Initializer using `ClusteredLocation`
    init(clusteredLocation: ClusteredLocation) {
        
        /// Create new date formatter
        let dateFormatter = DateFormatter()
        
        /// Check if location has only been seen today - if yes, we do not need to show the date, but only the time
        if Calendar.current.isDateInToday(clusteredLocation.startDate) {
            dateFormatter.dateStyle = .none
        }
        else {
            dateFormatter.dateStyle = .short
        }
        
        /// Set the time and locale settings accordingly
        dateFormatter.timeStyle = .short
        dateFormatter.locale = Locale.current
        
        /// Extract the coordinate from the clusteredLocation
        self.coordinate = clusteredLocation.location
        
        /// The string for the start date
        let startDateString = dateFormatter.string(from: clusteredLocation.startDate)
        
        /// The string for the end date
        let endDateString = dateFormatter.string(from: clusteredLocation.endDate)
        
        /// Create the title of the location - This is going to be the first time the tracker was seen at the location to the last time the tracker was seen at the location
        self.title = startDateString == endDateString ?
        /// if start and end date are the same, we do not need to show them twice
        startDateString :
        /// start and end date are different
        startDateString + " - " +  endDateString
        
        /// Set the subtitle to the lowest accuracy for the location
        self.subtitle = "accuracy".localized() + ": \(Int(clusteredLocation.worstAccuracy))m"
        
        super.init()
    }
}


/// Extension to make CLLocationCoordinate2D conform to Equatable, Identifiable and Hashable
extension CLLocationCoordinate2D: Equatable, Hashable, Identifiable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.id == rhs.id
    }
    
    public var id: String {
        "\(latitude)-\(longitude)"
    }
}


struct Previews_MapView_Previews: PreviewProvider {
    static var previews: some View {
        
        let loc1 = CLLocationCoordinate2D(latitude: 51, longitude: 8)
        
        let loc2 = CLLocationCoordinate2D(latitude: 52, longitude: 9)
        
        
        let mapAnnotation1 = MapAnnotation(clusteredLocation: ClusteredLocation(location: loc1, startDate: .distantPast, endDate: .distantPast, worstAccuracy: 10))
        
        let mapAnnotation2 = MapAnnotation(clusteredLocation: ClusteredLocation(location: loc2, startDate: .distantPast, endDate: .distantPast, worstAccuracy: 10))
        
        MapView(annotations: [mapAnnotation1, mapAnnotation2], connections: [loc1, loc2], mapFinishedLoading: .constant(true))
    }
}
