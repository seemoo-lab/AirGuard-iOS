//
//  ScanningAnimation.swift
//  AirGuard
//
//  Created by Leon Böttger on 02.05.22.
//

import SwiftUI

struct ScanAnimation: View {
    
    @State var rotation = false
    let size: CGFloat
    
    @State var withBackground = false
    
    var body: some View {
        
        ZStack {
            
            let altColor = Color.accentColor
            
            AngularGradient(gradient: Gradient(colors: withBackground ? [.white.opacity(0.1), .white] : [.white, altColor]), center: .center)
                .mask(Circle())
            
                .overlay(ZStack {
                    
                    let smallerSize = size * 0.15
                    
                    
                    Circle()
                        .stroke(style: StrokeStyle(lineWidth: size * 0.03, lineCap: .round, lineJoin: .round))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(width: size * 0.7, height: size * 0.7)
                    
                    
                    let whiteBorderSize = smallerSize + size * 0.1
                    
                    Circle()
                        .foregroundColor(.white)
                        .frame(width: whiteBorderSize, height: whiteBorderSize)
                    

                    Circle()
                        .foregroundColor(altColor)
                        .frame(width: smallerSize, height: smallerSize)
                })
            
                .rotationEffect(Angle(degrees: rotation ? 360 : (withBackground ? -65 : 0)), anchor: .center)
                .animation(Animation.linear(duration: 3).repeatForever(autoreverses: false), value: rotation)
                .onAppear {
                    // required due to swiftui bug
                    DispatchQueue.main.async {
                        
                        rotation = !withBackground
                    }
                }
        }
        .frame(width: size, height: size)
        .padding(withBackground ? size * 0.2 : 0)
        .background(LinearGradient(colors: withBackground ? [Color(#colorLiteral(red: 0.008081560023, green: 0.5630413294, blue: 0.9129524827, alpha: 1)), Color(#colorLiteral(red: 0.2278856039, green: 0.3596727252, blue: 0.7548273206, alpha: 1))] : [.clear], startPoint: .top, endPoint: .bottom))
        .compositingGroup()
    }
}


struct Previews_ScanningAnimation_Previews: PreviewProvider {
    static var previews: some View {
        ScanAnimation(size: 250, withBackground: true)
    }
}
