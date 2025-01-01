//
//  RiskView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 24.06.22.
//

import SwiftUI

let days = 14

struct RiskView: View {
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \TrackerNotification.time, ascending: false)],
        predicate: NSPredicate(format: "time >= %@", Calendar.current.date(byAdding: .day, value: -days, to: Clock.sharedInstance.currentDate)! as CVarArg),
        animation: .spring())
    private var notifications: FetchedResults<TrackerNotification>
    
    @ObservedObject var settings = Settings.sharedInstance
    
    var body: some View {
        
        let arr = Array(notifications)
        
        LUILink(style: .Plain, destination: RiskDetailView(notifications: arr), label: {
            RiskCardView(notifications: arr)
        })
        .allowsHitTesting(settings.backgroundScanning)
        .contentShape(Rectangle())
        .if(!settings.backgroundScanning, transform: { view in
            view.onTapGesture {
                Settings.sharedInstance.selectedTab = .Settings
            }
        })
    }
}


struct RiskCardView: View {
    
    let notifications: [TrackerNotification]
    @ObservedObject var settings = Settings.sharedInstance
    
    var body: some View {
        
        let status = getRiskStatus()
        let trackerCount = notifications.count == 0 ? "no".localized() : String(notifications.count)
        
        let text = status == .Unknown ? "background_scanning_disabled" :
        String(format: "x_potential_trackers_detected".localized(), trackerCount, (notifications.count == 1 ? "alert_singular" : "alert_plural").localized(), days.description)
        
        CardView(backgroundColor: status.color, title: status.title, titleSymbol: status.symbol) {
            HStack {
                CardSubView(symbol: "magnifyingglass", text: text)
                
                if(status != .Unknown) {
                    Image(systemName: "chevron.right")
                }
            }
        }
    }
    
    func getRiskStatus() -> RiskStatus {
        
        if(!settings.backgroundScanning) {
            return .Unknown
        }
        
        // do not count false alarms
        let notifications = notifications.filter({!$0.falseAlarm && !($0.baseDevice?.ignore ?? false)})
        
        let count = notifications.count
        
        // no notifications, no risk
        if(count == 0) {
            return .NoRisk
        }
        
        // more than 5 notifications or two notifications not more than 5 days apart means that the risk is high.
        else if(count > 5 || notifications.contains(where: { elem in
            notifications.contains(where: { elem2 in
                
                if elem != elem2, let time1 = elem.time, let time2 = elem2.time {
                    return abs(time1.distance(to: time2)) < daysToSeconds(days: 5)
                }
                return false
            })
        })) {
            return .HighRisk
        }
        
        // otherwise we show that the risk is medium
        else {
            return .MediumRisk
        }
    }
    
}


enum RiskStatus {
    
    case NoRisk
    case MediumRisk
    case HighRisk
    case Unknown
    
    var title: String {
        switch self {
        case .NoRisk:
            return "no_risk"
        case .MediumRisk:
            return "medium_risk"
        case .HighRisk:
            return "high_risk"
        case .Unknown:
            return "unknown_risk"
        }
    }
    
    var symbol: String {
        switch self {
        case .NoRisk:
            return "checkmark.shield.fill"
        case .MediumRisk:
            return "exclamationmark.shield.fill"
        case .HighRisk:
            return "xmark.shield.fill"
        case .Unknown:
            return "questionmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .NoRisk:
            return .green
        case .MediumRisk:
            return .orange
        case .HighRisk:
            return .red
        case .Unknown:
            return .red
        }
    }
}


struct Previews_RiskView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            RiskCardView(notifications: [])
        }
    }
}
