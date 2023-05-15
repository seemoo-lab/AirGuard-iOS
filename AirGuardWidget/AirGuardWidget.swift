//
//  AirGuardWidget.swift
//  AirGuardWidget
//
//  Created by Leon Böttger on 08.06.22.
//
import WidgetKit
import SwiftUI
import CoreBluetooth

struct Provider: TimelineProvider {
    
    // That way we can inject CoreBluetooth into the widget
    // @ObservedObject var bluetoothManager = BluetoothManager.sharedInstance
    
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        
        // force start Bluetooth
        //        if Settings.sharedInstance.backgroundScanning {
        //            bluetoothManager.startCentralManager()
        //            bluetoothManager.startScan()
        //        }
        
        let timeline = Timeline(entries: [SimpleEntry(date: Date())], policy: .after(Date().addingTimeInterval(60 * 15)))
        
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct AirGuardWidgetEntryView : View {
    var entry: Provider.Entry
    //    @ObservedObject var bluetoothManager = BluetoothManager.sharedInstance
    
    var body: some View {
        VStack {
            Text("Last Widget Refresh: ")
            + Text(entry.date, style: .time)
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(gradient: .init(colors: Constants.defaultColors), startPoint: .bottomLeading, endPoint: .topTrailing))
        
    }
}

@main
struct AirGuardWidget: Widget {
    let kind: String = "AirGuardWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AirGuardWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("AirGuard Widget")
        .description("Monitor trackers around you from the background!")
        .supportedFamilies([]) // disable widget for now
    }
}

struct AirGuardWidget_Previews: PreviewProvider {
    static var previews: some View {
        AirGuardWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
