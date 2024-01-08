//
//  DetailNotificationsView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.08.22.
//

import SwiftUI

struct DetailNotificationsView: View {
    
    @ObservedObject var tracker: BaseDevice
    @ObservedObject var clock = Clock.sharedInstance
    
    var body: some View {
        
        let notifications = (tracker.notifications?.array as? [TrackerNotification] ?? []).reversed()
        
        if(!notifications.isEmpty && !tracker.ignore) {
            CustomSection(header: "notifications", footer: "false_alarm_description") {
                
                NavigationLink(destination: ArticleView(article: helpArticle)) {
                    NavigationLinkLabel(imageName: "questionmark.bubble.fill", text: "get_help", backgroundColor: .purple, isNavLink: true)
                }
                
                ForEach(notifications, id: \.self) { notification in
                    
                    if let time = notification.time {
                        HStack {
                            Text(getSimpleSecondsText(seconds: Int(-time.timeIntervalSince(clock.currentDate)), longerDate: false))
                                .foregroundColor(Color("MainColor"))
                                .frame(height: Constants.SettingsLabelHeight)
                            
                            Spacer()
                            
                            FalseAlarmButton(notification: notification)
                        }
                    }
                    
                    if(notification != notifications.last) {
                        CustomDivider()
                    }
                }
            }
        }
    }
}


struct FalseAlarmButton: View {
    
    @ObservedObject var notification: TrackerNotification
    
    let persistenceController = PersistenceController.sharedInstance
    
    var body: some View {
        
        Button {
            mediumVibration()
            
            let id = notification.objectID
            
            persistenceController.modifyDatabaseBackground { context in
                if let notification = context.object(with: id) as? TrackerNotification {
                    notification.falseAlarm.toggle()
                }
            }
            
        } label: {
            if(notification.falseAlarm) {
                Text("unmark_false_alarm")
                
            }
            else {
                Text("mark_false_alarm")
            }
        }
        .lineLimit(1)
    }
}
