//
//  StudyOptInView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 05.06.22.
//

import SwiftUI

struct StudyOptInView: View {
    
    var selectionAction: ((_ participate: Bool)->())?
    
    var body: some View {
        
        BigButtonView(buttonHeight: Constants.BigButtonHeight*2,
                      mainView:
        BigSymbolView(title: "our_study", symbol: "person.3.fill", imageFontSize: 75) {
            
            Text("our_study_description")
                .multilineTextAlignment(.leading)
                .lineSpacing(4)
            
        }, buttonView: StudyOptInButtonView(selectionAction: selectionAction))
        .onAppear {
            Settings.sharedInstance.askedForStudyParticipation = true
        }
    }
}


struct StudyOptInButtonView: View {
    
    let settings = Settings.sharedInstance
    @State private var linkActive = false
    @State private var ageConfirmed = false
    var selectionAction: ((_ participate: Bool)->())?
    
    var body: some View {
        
        VStack(spacing: Constants.SettingsSectionSpacing) {
            
            CheckboxButton(isSelected: $ageConfirmed , label: Text("age_confirmation"))
                .frame(minWidth: 0, maxWidth: .infinity,alignment: .center)
                .padding(.horizontal, 32)
                .padding(.top)
            
            ColoredButton(action: {
                
                settings.participateInStudy = true
                linkActive = true
                selectionAction?(true)
                
            }, label: "participate_study", colors: [.accentColor, .accentColor])
            .disabled(!self.ageConfirmed)
            
            
            ColoredButton(action: {
                
                settings.participateInStudy = false
                linkActive = true
                selectionAction?(false)
                
            }, label: "dont_participate_study")
            
        }
        .modifier(LinkTo(content: IntroductionDoneView.init, isActive: $linkActive))
    }
}

struct CheckboxButton: View {
    
    @Binding var isSelected: Bool
    var label: Text
    
    var body: some View {
        Button {
            withAnimation {
                self.isSelected.toggle()
            }
        } label: {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(.accentColor)
                
                label
                    .foregroundColor(Color("DarkBlue"))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct Previews_StudyOptInView_Previews: PreviewProvider {
    static var previews: some View {
        StudyOptInView()
    }
}
