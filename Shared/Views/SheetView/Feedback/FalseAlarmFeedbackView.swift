//
//  TrackingFeedbackView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 24.01.24.
//

import SwiftUI

struct FalseAlarmFeedbackView: View {
    
    let notification: TrackerNotification
    @Binding var showSheet: Bool
    @State var showDoneView = false
    @State var showAdditionalFeedbackView = false
    
    var body: some View {
        BigButtonView(buttonHeight: Constants.BigButtonHeight * 2, mainView: BigSymbolViewWithText(title: "feedback_view_false_alarm_header", symbol: "exclamationmark.shield.fill", subtitle: "feedback_view_false_alarm_subtitle", topPadding: 0), buttonView:
                        
                        VStack(spacing: 15) {
            ColoredButton(action: {
                
                PersistenceController.sharedInstance.modifyDatabase { context in
                    notification.falseAlarm = true
                    notification.hideout = nil
                    notification.providedFeedback = true
                    showDoneView = true
                }
                
            }, label: "feedback_view_false_alarm_mark_as_false_alarm", colors: [.airGuardBlue], invertColors: true)
            
            ColoredButton(action: {
                
                PersistenceController.sharedInstance.modifyDatabase { context in
                    notification.falseAlarm = false
                    notification.providedFeedback = true
                    showAdditionalFeedbackView = true
                }
                
            }, label: "feedback_view_false_alarm_mark_as_threat", colors: [.red], invertColors: false)
            
        }, hideNavigationBar: false)
        .modifier(LinkTo(content: {FeedbackThanksView(showSheet: $showSheet)}, isActive: $showDoneView))
        .modifier(LinkTo(content: {AdditionalFeedbackView(notification: notification, showSheet: $showSheet)}, isActive: $showAdditionalFeedbackView))
        .navigationBarTitle("‏‏‎ ‎‎", displayMode: .inline)
    }
}


#Preview {
    NavigationView {
        FalseAlarmFeedbackView(notification: TrackerNotification(context: PersistenceController.sharedInstance.container.viewContext), showSheet: .constant(false))
    }
}
