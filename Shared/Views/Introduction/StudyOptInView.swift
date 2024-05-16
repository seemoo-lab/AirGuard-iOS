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
        
        BigButtonView(buttonHeight: Constants.BigButtonHeight + 50,
                      mainView:
        BigSymbolView(title: "our_study", symbol: "waveform.path.ecg", imageFontSize: 75) {
            
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
        
        VStack() {
            
            Spacer()
            Spacer()
            
            CheckboxButton(isSelected: $ageConfirmed , label: Text("age_confirmation"))
                .frame(minWidth: 0, maxWidth: .infinity,alignment: .center)
            
            Spacer()
            Spacer()
            
            HStack(spacing: 13) {
                
                ColoredButton(action: {
                    
                    settings.participateInStudy = true
                    linkActive = true
                    selectionAction?(true)
                    
                }, label: "participate", colors: [.airGuardBlue, .airGuardBlue], hasPadding: false)
                .disabled(!self.ageConfirmed)

                
                ColoredButton(action: {
                    
                    settings.participateInStudy = false
                    linkActive = true
                    selectionAction?(false)
                    
                }, label: "dont_participate", hasPadding: false)

            }
            .padding(.horizontal)
            
            Spacer()
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
                    .foregroundColor(.airGuardBlue)
                
                label
                    .foregroundColor(.mainColor)
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
