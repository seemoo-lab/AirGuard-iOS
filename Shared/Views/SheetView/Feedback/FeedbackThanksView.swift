//
//  TrackingFeedbackView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 24.01.24.
//

import SwiftUI


struct FeedbackThanksView: View {
    
    @Binding var showSheet: Bool
    
    var body: some View {
        BigButtonView(buttonHeight: Constants.BigButtonHeight, mainView: BigSymbolViewWithText(title: "feedback_view_thanks_header", symbol: "checkmark", subtitle: "feedback_view_thanks_subtitle", topPadding: 0), buttonView:
                        
                        VStack(spacing: 15) {
            GrayButton(label: "feedback_view_thanks_done_button", action: {
                showSheet = false
                
            })
            
        }, hideNavigationBar: false)
    }
}


#Preview {
    NavigationView {
        FeedbackThanksView(showSheet: .constant(false))
    }
}
