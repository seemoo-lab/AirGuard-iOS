//
//  DoneView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 05.06.22.
//

import SwiftUI


struct IntroductionDoneView: View {
    
    let settings = Settings.sharedInstance
    
    var body: some View {
        
        BigButtonView(buttonHeight: Constants.BigButtonHeight, mainView: BigSymbolViewWithText(title: "all_done", symbol: "checkmark.circle.fill", subtitle: "all_done_description"), buttonView: ColoredButton(action: {
            settings.tutorialCompleted = true
        }, label: "continue"))
    }    
}


struct Previews_IntroductionDoneView_Previews: PreviewProvider {
    static var previews: some View {
        IntroductionDoneView()
    }
}
