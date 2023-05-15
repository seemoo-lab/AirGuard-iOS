//
//  EnableObservationSheet.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 05.08.22.
//

import SwiftUI

struct EnableObservationSheet: View {
    
    @Binding var showSheet: Bool
    
    var body: some View {
        
        BigButtonView(buttonHeight: Constants.BigButtonHeight, mainView: BigSymbolViewWithText(title: "observe_tracker", symbol: "clock.fill", subtitle: "observe_tracker_description"), buttonView: ColoredButton(action: {
            showSheet = false
        }, label: "continue"))
        
    }
}
