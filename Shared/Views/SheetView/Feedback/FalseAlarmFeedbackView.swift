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
        
        NavigationSubView {
            
            BigSymbolViewWithText(title: "feedback_view_false_alarm_header", symbol: "exclamationmark.shield.fill", subtitle: "feedback_view_false_alarm_subtitle", topPadding: 0)

            CustomSection(footer: "feedback_view_false_alarm_mark_as_false_alarm_footer") {

                LUIButton {
                    let id = notification.objectID
                    showDoneView = true
                    
                    PersistenceController.sharedInstance.modifyDatabaseBackground { context in
                        
                        if let notification = context.object(with: id) as? TrackerNotification {
                            notification.falseAlarm = true
                            notification.hideout = nil
                            notification.providedFeedback = true
                        }
                    }
                } label: {
                    NavigationLinkLabel(imageName: "checkmark.shield.fill", text: "feedback_view_false_alarm_mark_as_false_alarm", backgroundColor: .green)
                }
            }
            .padding(.bottom)
                
            CustomSection(footer: "feedback_view_false_alarm_mark_as_threat_footer") {
                LUIButton {
                    let id = notification.objectID
                    showAdditionalFeedbackView = true
                    
                    PersistenceController.sharedInstance.modifyDatabaseBackground { context in
                        
                        if let notification = context.object(with: id) as? TrackerNotification {
                            notification.falseAlarm = false
                            notification.providedFeedback = true
                        }
                    }
                } label: {
                    NavigationLinkLabel(imageName: "xmark.shield.fill", text: "feedback_view_false_alarm_mark_as_threat", backgroundColor: .red)
                }
            }
        }
        .modifier(LinkTo(content: {FeedbackThanksView(showSheet: $showSheet)}, isActive: $showDoneView))
        .modifier(LinkTo(content: {AdditionalFeedbackView(notification: notification, showSheet: $showSheet)}, isActive: $showAdditionalFeedbackView))
        .navigationBarItems(trailing: XButton(action: {showSheet = false}))
    }
}


#Preview {
    NavigationView {
        FalseAlarmFeedbackView(notification: TrackerNotification(context: PersistenceController.sharedInstance.container.viewContext), showSheet: .constant(false))
    }
}



public struct XButton: View {
    
    public init(action: @escaping () -> ()) {
        self.action = action
    }
    
    let action: () -> ()
    
    public var body: some View {
        RoundGrayButton(imageName: "xmark", action: action)
    }
}


public struct RoundGrayButton: View {
    
    public init(imageName: String, action: @escaping () -> ()) {
        self.imageName = imageName
        self.action = action
    }
    
    let imageName: String
    let action: () -> ()
    
    public var body: some View {
        LUIButton(action: action, label: {
            RoundGrayIcon(imageName: imageName)
        })
    }
}


public struct RoundGrayIcon: View {
    
    public init(imageName: String, color: Color = .grayColor) {
        self.imageName = imageName
        self.color = color
    }
    
    let imageName: String
    let color: Color
    
    public var body: some View {
        
        let sz = 16.5
        
        Image(systemName: imageName)
            .scaleEffect(0.9)
            .font(.system(size: 12).weight(.heavy))
            .foregroundColor(color)
            .frame(width: sz, height: sz)
            .padding(7)
            .background(Circle().foregroundColor(color.opacity(0.15)))
    }
}
