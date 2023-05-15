//
//  BigButtonView.swift
//  AirGuard
//
//  Created by Leon Böttger on 31.10.20.
//  Copyright © 2020 Leon Böttger. All rights reserved.
//

import SwiftUI

struct BigButtonView<T1: View, T2: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var blurOpacity: Double = 0
    let buttonHeight: CGFloat
    let mainView: T1
    let buttonView: T2
    @State var hideNavigationBar = true
    
    var body: some View {
        
        ZStack {
            GeometryReader { geometry in
                
                ScrollView(showsIndicators: false){
                    VStack(){
                        //content
                        mainView
                        
                    }.frame(minHeight: geometry.size.height - buttonHeight)
                        .padding(.bottom, buttonHeight)
                }
                .frame(maxWidth: .infinity)
            }
            
            
            //button
            VStack {
                
                Spacer()
                //content2
                buttonView
                    .frame(maxWidth: .infinity)
                    .frame(height: buttonHeight)
                    .background(Blur().brightness(getBrightness()).edgesIgnoringSafeArea(.all))
            }
            
            .ignoresSafeArea(.keyboard)

        }
        .modifier(CustomFormBackground())
        .navigationViewStyle(.stack)
        .navigationBarHidden(hideNavigationBar)
    }
    
    func getBrightness() -> Double {
        return colorScheme == .light ? 0.04 : -0.065
        
    }
}


struct ColoredButton: View {
    
    let action: () -> ()
    let label: String
    var colors: [Color] = Constants.defaultColors
    
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    var body: some View {
        Button(action: {
            
            mediumVibration()
            action()
            
        }) {
            Text(label.localized())
                .customButton(colors: colors)
        }
        .padding(.horizontal)
        .opacity(isEnabled ? 1 : 0.5)
    }
}
