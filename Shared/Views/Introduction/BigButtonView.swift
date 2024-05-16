//
//  BigButtonView.swift
//  AirGuard
//
//  Created by Leon Böttger on 31.10.20.
//  Copyright © 2020 Leon Böttger. All rights reserved.
//

import SwiftUI

struct BigButtonView<T1: View, T2: View>: View {
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
                    .background(TintedBlur().edgesIgnoringSafeArea(.all))
            }
            
            .ignoresSafeArea(.keyboard)

        }
        .modifier(CustomFormBackground())
        .navigationViewStyle(.stack)
        .navigationBarHidden(hideNavigationBar)
        .overlay(
            GeometryReader { geo in
                VStack {
                    TintedBlur()
                        .frame(height: geo.safeAreaInsets.top)
                    Spacer()
                }
                .offset(y: -geo.safeAreaInsets.top)
            }
        )
    }
}

struct TintedBlur: View {
    
    @Environment(\.sheetActive) private var sheetActive
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Blur().brightness(getBrightness())
    }
    
    func getBrightness() -> Double {
        if sheetActive {
            return colorScheme == .light ? 0.02 : -0.075
        }
        return colorScheme == .light ? 0.01 : -0.2
    }
}


struct ColoredButton: View {
    
    let action: () -> ()
    let label: String
    var colors: [Color] = Constants.defaultColors
    var hasPadding = true
    var invertColors = false
    
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    var body: some View {
        LUIButton(action: {
            lightVibration()
            action()
        }) {
            Text(label.localized())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .customButton(colors: colors, invert: invertColors)
        }
        .padding(hasPadding ? .horizontal : .horizontal, 0)
        .opacity(isEnabled ? 1 : 0.5)
    }
}


#Preview {
    Group {
//        IntroductionView()
  //          .navigationViewStyle(StackNavigationViewStyle())
        
        
        Color.clear
            .luiSheet(isPresented: .constant(true), content: {
                NavigationView {
                    IntroductionView()
                        .navigationTitle("Test")
                        .navigationViewStyle(StackNavigationViewStyle())
                }
                   
            })
    }
}
