//
//  DetailNotificationsView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.08.22.
//

import SwiftUI

struct DetailNotificationsView: View {
    
    @ObservedObject var tracker: BaseDevice
    
    var body: some View {
        
        let notifications = (tracker.notifications?.array as? [TrackerNotification] ?? []).reversed()
        
        if(!notifications.isEmpty && !tracker.ignore) {
            CustomSection(header: "notifications") {
                
                LUILink(destination: ArticleView(article: helpArticle)) {
                    NavigationLinkLabel(imageName: getFAQIcon(), text: "get_help", backgroundColor: .purple, isNavLink: true)
                }
                
                ForEach(notifications, id: \.self) { notification in
                    NotificationInfoView(notification: notification)
                }
            }
        }
    }
}

struct NotificationInfoView: View {
    
    @ObservedObject var clock = Clock.sharedInstance
    @ObservedObject var notification: TrackerNotification
    @State var showFeedbackSheet = false
    
    var body: some View {
        
        if let time = notification.time {
            HStack {
                VStack {
                    Text(getSimpleSecondsText(seconds: Int(-time.timeIntervalSince(clock.currentDate)), longerDate: false))
                        .foregroundColor(.mainColor)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    
                        Text(getFeedbackString(notification: notification))
                            .foregroundColor(.mainColor)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .opacity(0.6)
                }
                .frame(height: Constants.SettingsLabelHeight)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                
                Spacer()
                
                LUIButton {
                    showFeedbackSheet = true
                } label: {
                    Text("Feedback ›")
                        .foregroundColor(.airGuardBlue)
                }
                .luiSheet(isPresented: $showFeedbackSheet, content: {
                    NavigationView {
                        FalseAlarmFeedbackView(notification: notification, showSheet: $showFeedbackSheet)
                    }
                })
            }
        }
    }
    
    func getFeedbackString(notification: TrackerNotification) -> String {
        if notification.providedFeedback {
            if let hideoutString = notification.hideout, let hideout = TrackerHideout(rawValue: hideoutString){
                return "tracker_detail_notifications_tracker_hideout".localized() + ": " + hideout.label().localized()
            }
            if !notification.falseAlarm {
                return "tracker_detail_notifications_tracker_marked_as_threat".localized()
            }
            return "tracker_detail_notifications_tracker_marked_as_false_alarm".localized()
        }
        return "tracker_detail_notifications_tracker_no_feedback_saved".localized()
    }
}
