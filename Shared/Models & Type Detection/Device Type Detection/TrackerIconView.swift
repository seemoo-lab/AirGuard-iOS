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
            .foregroundColor(.airGuardBlue)
            .frame(width: size, height: size)
            .overlay(
                LinearGradient(colors: [.clear, .white.opacity(0.2)], startPoint: .bottom, endPoint: .top)
                    .mask(content)
            )
            .overlay(
                
                Group {
                    if(imageName != "") {
                        Image(systemName: imageName)
                            .font(.system(size: size * 0.6))
                            .offset(x: -size * 0.01, y: -size * 0.02)
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
