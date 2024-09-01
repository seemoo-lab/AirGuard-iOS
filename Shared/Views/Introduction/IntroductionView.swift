//
//  IntroductionView.swift
//  AirGuard
//
//  Created by Leon Böttger on 16.06.20.
//  Copyright © 2020 Leon Böttger. All rights reserved.
//

import SwiftUI

struct IntroductionView: View {
    
    @StateObject var controller = IntroducationViewController.sharedInstance
    
    var body: some View {

        NavigationView {
            BigButtonView(buttonHeight: Constants.BigButtonHeight, mainView: IntroductionMainView(), buttonView: IntroductionButtonView(action: {
                IntroducationViewController.sharedInstance.canProceed = true
            }) {
                BluetoothPermissionView()
            })
        }
    }
}

struct IntroductionMainView: View {
    var body: some View {
        Spacer()
        TitleView(title: "welcome_to")
        
        Spacer()
        
        InformationContainerView()
            .padding(.vertical)
            
        Spacer()
        Spacer()
    }
}


struct LinkTo<V0: View>: ViewModifier {
    
    @Binding var isActive: Bool
    let destination: () -> V0
    
    init(@ViewBuilder content: @escaping () -> V0, isActive: Binding<Bool>) {
        destination = content
        self._isActive = isActive
    }
    
    func body(content: Content) -> some View {
        content
            .background(LUILink(destination: destination(), isActive: $isActive)
                .disabled(true)
                .hidden())
    }
}


class IntroducationViewController: ObservableObject {
    
    static var sharedInstance = IntroducationViewController()
    
    private init() {}
    
    @Published var canProceed = false {
        didSet {
            log("canproceed: \(canProceed)")
        }
    }
}


struct IntroductionButtonView<V0: View>: View {
    
    @State private var linkActive = false
    let action: () -> ()
    private let destination: () -> V0
    
    @ObservedObject var controller = IntroducationViewController.sharedInstance
    
    init(action: @escaping () -> (), @ViewBuilder nextView: @escaping () -> V0) {
        destination = nextView
        self.action = action
    }
    
    var body: some View {
 
        
        GrayButton(label: "continue", action: {

            if(controller.canProceed) {
                controller.canProceed = false
                linkActive = true
            }
            else {
                action()
            }
        })
            .modifier(LinkTo(content: destination, isActive: $linkActive))
            .onChange(of: controller.canProceed) { newValue in
                if(newValue && !linkActive) {
                    controller.canProceed = false
                    linkActive = true
                }
            }
    }
}


struct InformationContainerView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            InformationDetailView(title: "manual_scan", subTitle: "manual_scan_description", imageName: "magnifyingglass")
            
            InformationDetailView(title: "background_scan", subTitle: "background_scan_description", imageName: "exclamationmark.bubble")
            
            InformationDetailView(title: "respect_data", subTitle: "respect_data_description", imageName: "lock")
        }
        .padding(.horizontal)
    }
}


struct TitleView: View {
    let title: String
    
    var body: some View {
        VStack {
            
            Text(title.localized())
                .customTitleText()
                .padding(.top)
            
            Text("AirGuard")
                .customTitleText()
                .gradientForeground(gradient: LinearGradient(gradient: .init(colors: Constants.defaultColors), startPoint: .bottomLeading, endPoint: .topTrailing))
        }
    }
}


struct InformationDetailView: View {
    var title: String
    var subTitle: String
    var imageName: String
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: imageName)
                .font(.largeTitle)
                .gradientForeground(gradient: LinearGradient(gradient: .init(colors: Constants.defaultColors), startPoint: .bottomLeading, endPoint: .topTrailing))
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(title.localized())
                    .font(.headline)
                    .foregroundColor(.primary)
                    .padding(.bottom, 3)
         
                
                Text(subTitle.localized())
                    .fixedSize(horizontal: false, vertical: true)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.top)
        .padding(.trailing)
    }
}


struct IntroductionView_Previews: PreviewProvider {
    static var previews: some View {
        Group{
            IntroductionView()
        }.navigationViewStyle(StackNavigationViewStyle())
    }
}
