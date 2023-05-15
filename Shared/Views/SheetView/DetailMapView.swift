//
//  DetailMapView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.08.22.
//

import SwiftUI
import CoreLocation
import CoreData

struct DetailMapView: View {
    
    @ObservedObject var tracker: BaseDevice
    @State var smallMapFinishedLoading = false
    
    var body: some View {
        Group {
            if let detections = tracker.detectionEvents?.array as? [DetectionEvent], !tracker.ignore {
                
                let connections = detections.compactMap({$0.location}).map({CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)})
                
                let coordinates = detectionToCoordinates(detectionEvents: detections)
                
                let annotations = coordinates.map({MapAnnotation(clusteredLocation: $0)})
                
                if(annotations.count > 0) {
                    
                    NavigationLink {
                        MapView(annotations: annotations, connections: connections, mapFinishedLoading: .constant(true))
                            .ignoresSafeArea(.all, edges: [.horizontal, .bottom])
                            .navigationTitle("tracker_locations")
                            .navigationBarTitleDisplayMode(.inline)
                            .background(ProgressView())
                        
                    } label: {
                        MapView(annotations: annotations, connections: connections, mapFinishedLoading: $smallMapFinishedLoading)
                            .overlay(
                                ZStack {
                                    VStack {
                                        
                                        HStack {
                                            Spacer()
                                            
                                            ZStack {
                                                Blur(style: .systemUltraThinMaterialDark)
                                                    .cornerRadius(10)
                                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                                    .foregroundColor(.white)
                                            }
                                            
                                            .frame(width: 30, height: 30, alignment: .center)
                                            .padding()
                                        }
                                        
                                        Spacer()
                                    }
                                })
                            .background(ProgressView())
                            .allowsHitTesting(false)
                            .compositingGroup()
                            .frame(height: 200)
                        
                    }
                        .modifier(FormModifierNoPadding(showShadow: !smallMapFinishedLoading))
                        .animation(.easeInOut, value: !smallMapFinishedLoading)
                }
                
                else {
                    MapPlaceholderView(isTrackerIgnored: tracker.ignore)
                }
            }
            else {
                MapPlaceholderView(isTrackerIgnored: tracker.ignore)
            }
        }
        .padding(.horizontal)
        
    }
}

struct MapPlaceholderView: View {
    
    let isTrackerIgnored: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            Image(systemName: "map.fill")
                .font(.largeTitle)
                .centered()
                .lowerOpacity(darkModeAsWell: true)
                .foregroundColor(.accentColor)
                .padding(.bottom, 5)
            
            HStack {
                Spacer()
                
                Text(isTrackerIgnored ? "map_unavailable_ignored" : "map_unavailable_no_locations")
                    .bold()
                    .foregroundColor(formHeaderColor)
                    .centered()
                    .padding(.horizontal)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            
            Spacer()
        }
        .padding(.vertical)
        .modifier(FormModifier())
    }
}


/// Extracts the coordinates of detection events to ClusteredLocation
func detectionToCoordinates(detectionEvents: [DetectionEvent]) -> [ClusteredLocation] {
    
    var processedLocations = [NSManagedObjectID : ClusteredLocation]()
    
    for event in detectionEvents {
        
        if let location = event.location, let time = event.time {
            if processedLocations[location.objectID] == nil {
                
                let cllocation = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
                
                let data = ClusteredLocation(location: cllocation, startDate: time, endDate: time, worstAccuracy: location.accuracy)
                
                processedLocations[location.objectID] = data
            }
            else {
                
                processedLocations[location.objectID]?.endDate = time
                
                if(location.accuracy > processedLocations[location.objectID]?.worstAccuracy ?? 0) {
                    processedLocations[location.objectID]?.worstAccuracy = location.accuracy
                }
            }
        }
    }
    
    return processedLocations.values.map({$0})
}


/// Struct to store data of the locations shown on the map
struct ClusteredLocation {
    let location: CLLocationCoordinate2D
    let startDate: Date
    var endDate: Date
    var worstAccuracy: Double
}


struct Previews_DetailMapView_Previews: PreviewProvider {
    static var previews: some View {
        
        let vc = PersistenceController.sharedInstance.container.viewContext
        
        let device = BaseDevice(context: vc)
        device.setType(type: .AirTag)
        device.firstSeen = Date()
        device.lastSeen = Date()
        
        let detectionEvent = DetectionEvent(context: vc)
        
        detectionEvent.time = device.lastSeen
        detectionEvent.baseDevice = device
        
        let location = Location(context: vc)
        
        location.latitude = 52
        location.longitude = 8
        location.accuracy = 1
        
        detectionEvent.location = location
        
        try? vc.save()
        
        return VStack {
            DetailMapView(tracker: device)
                .environment(\.managedObjectContext, vc)
        }
    }
}
