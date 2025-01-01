//
//  AdditionalFeedbackView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 30.01.24.
//

import SwiftUI

struct AdditionalFeedbackView: View {
    
    let notification: TrackerNotification
    @Binding var showSheet: Bool
    @State var showDoneView = false
    
    var body: some View {
        NavigationSubView {
            
            BigSymbolViewWithText(title: "feedback_view_additional_feedback_header", symbol: getSymbol(), subtitle: "feedback_view_additional_feedback_subtitle", topPadding: 0)
            
            CustomSection {
                
                ForEach(TrackerHideout.allCases, id: \.self) { hideout in
                    LUIButton {
                        
                        let id = notification.objectID
                        showDoneView = true
                        
                        PersistenceController.sharedInstance.modifyDatabaseBackground { context in
                            
                            if let notification = context.object(with: id) as? TrackerNotification {
                                notification.hideout = hideout.rawValue
                            }
                        }
                    } label: {
                        NavigationLinkLabel(imageName: hideout.icon(), text: hideout.label(), backgroundColor: hideout.color())
                    }
                }
            }
        }
        .modifier(LinkTo(content: {FeedbackThanksView(showSheet: $showSheet)}, isActive: $showDoneView))
        .navigationBarItems(trailing: XButton(action: {showSheet = false}))
    }
    
    func getSymbol() -> String {
        if #available(iOS 15.0, *) {
            return "sensor.tag.radiowaves.forward.fill"
        } else {
            return "location.fill.viewfinder"
        }
    }
}

enum TrackerHideout: String, CaseIterable {
    case Bag
    case Clothes
    case Car
    case Bicycle
    case Other
    case NotFound
    
    func label() -> String {
        switch self {
        case .Bag:
            return "feedback_view_additional_feedback_bag"
        case .Clothes:
            return "feedback_view_additional_feedback_clothes"
        case .Car:
            return "feedback_view_additional_feedback_car"
        case .Bicycle:
            return "feedback_view_additional_feedback_bicycle"
        case .Other:
            return "feedback_view_additional_feedback_other"
        case .NotFound:
            return "feedback_view_additional_feedback_not_found"
        }
    }
    
    func icon() -> String {
        switch self {
        case .Bag:
            return "backpack.fill"
        case .Clothes:
            return "tshirt.fill"
        case .Car:
            return "car.fill"
        case .Bicycle:
            return "bicycle"
        case .Other:
            return "ellipsis"
        case .NotFound:
            return "questionmark"
        }
    }
    
    func color() -> Color {
        switch self {
        case .Bag:
            return .blue
        case .Clothes:
            return Color(#colorLiteral(red: 0.3667442501, green: 0.422971189, blue: 0.9019283652, alpha: 1))
        case .Car:
            return .red
        case .Bicycle:
            return .orange
        case .Other:
            return .green
        case .NotFound:
            return .gray
        }
    }
}


#Preview {
    NavigationView {
        AdditionalFeedbackView(notification: TrackerNotification(context: PersistenceController.sharedInstance.container.viewContext), showSheet: .constant(false))
    }
}
