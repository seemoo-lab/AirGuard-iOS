//
//  PermissionView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 05.06.22.
//

import SwiftUI


struct PermissionView<V0: View>: View {
    
    let title: String
    let symbol: String
    let subtitle: String
    let action: () -> ()
    let canSkip: Bool
    let destination: () -> V0
    
    
    init(title: String, symbol: String, subtitle: String, action: @escaping () -> (), canSkip: Bool = false, @ViewBuilder nextView: @escaping () -> V0) {
        self.title = title
        self.symbol = symbol
        self.subtitle = subtitle
        self.action = action
        self.canSkip = canSkip
        destination = nextView
    }
    
    
    var body: some View {
        
        let height = canSkip ? Constants.BigButtonHeight + 50 : Constants.BigButtonHeight
        
        BigButtonView(buttonHeight: height, mainView: BigSymbolViewWithText(title: title, symbol: symbol, subtitle: subtitle), buttonView: VStack {
            
            if(canSkip) {
                Spacer()
                
                NoBackgroundScanningButton()
            }
            
            Spacer()
            
            IntroductionButtonView(action: action, nextView: destination)
            
            Spacer()
        })
    }
    
}

struct NoBackgroundScanningButton: View {
    
    @State var linkActive = false
    let settings = Settings.sharedInstance
    
    var body: some View {
        
        Button(action: {
            
            settings.backgroundScanning = false
            
            // quit re-enabling background scanning
            if(settings.appLaunchedBefore) {
                settings.tutorialCompleted = true
            }
            else {
                linkActive = true
            }
            

        }, label: {
            Text("skip_background_scanning")
            
        })
        
        .modifier(LinkTo(content: {
            if Constants.StudyIsActive {
                StudyOptInView()
            }else {
                IntroductionDoneView()
            }
        }, isActive: $linkActive))
    }
    
}

struct BigSymbolViewWithText: View {
    
    let title: String
    let symbol: String
    let subtitle: String
    @State var topPadding: CGFloat = 60
    
    var body: some View {
        BigSymbolView(title: title, symbol: symbol, topPadding: topPadding) {
            Text(subtitle.localized())
        }
    }
}


struct BigSymbolView<V0: View>: View {
    
    let title: String
    let symbol: String
    let textView: () -> V0
    let topPadding: CGFloat
    let imageFontSize: CGFloat
    let symbolPadding: CGFloat
    let textPadding: CGFloat
    
    init(title: String, symbol: String, topPadding: CGFloat = 60, imageFontSize: CGFloat = 100, symbolPadding: CGFloat = 20, textPadding: CGFloat = 20, @ViewBuilder textView: @escaping () -> V0) {
        self.title = title
        self.symbol = symbol
        self.textView = textView
        self.topPadding = topPadding
        self.imageFontSize = imageFontSize
        self.symbolPadding = symbolPadding
        self.textPadding = textPadding
    }
    
    var body: some View {
        
        VStack {
        
            Text(title.localized())
                .largeTitle()
                .centered()
                .foregroundColor(Color("DarkBlue"))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, topPadding)
                .padding(.horizontal)
            
            Spacer()
            Spacer()
            
            
            Image(systemName: symbol)
                .gradientForeground(gradient: LinearGradient(gradient: .init(colors: Constants.defaultColors), startPoint: .bottomLeading, endPoint: .topTrailing))
                .font(.system(size: imageFontSize, weight: .heavy, design: .default))
                .padding(symbolPadding)
            
            Spacer()
            
            textView()
                .frame(maxWidth: Constants.maxWidth)
                .padding()
                .padding(.horizontal, textPadding)
                .centered()
                .lowerOpacity(darkModeAsWell: true)
            
            Spacer()
            Spacer()
            
        }
    }
}


struct Previews_PermissionView_Previews: PreviewProvider {
    static var previews: some View {
        LocationPermissionView()
    }
}
