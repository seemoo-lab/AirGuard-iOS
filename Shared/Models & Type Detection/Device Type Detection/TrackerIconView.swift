//
//  TrackerIconView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 06.06.22.
//

import SwiftUI


/// Icon for tracker types
struct TrackerIconView: ViewModifier {
    @State var imageName: String = ""
    @State var text: String = "?"
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        
        let size = Constants.trackerIconViewSize
        
        content
            .foregroundColor(.accentColor.opacity(colorScheme.isLight ? 0.8 : 1))
            .frame(width: size, height: size)
            .overlay(
                
                Group {
                    if(imageName != "") {
                        Image(systemName: imageName)
                            .font(.system(size: size * 0.6))
                            .offset(y: -size * 0.02)
                    }
                    else {
                        Text(text)
                            .minimumScaleFactor(0.1)
                            .padding(size * 0.15)
                    }
                }
                    .foregroundColor(.white)
                
            )
            .padding(.vertical)
            .compositingGroup()
        
    }
}
