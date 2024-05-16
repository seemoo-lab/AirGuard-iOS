//
//  LUIButton.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 25.03.24.
//

import SwiftUI

public struct LUIButton<Content: View>: View {
    
    public init(action: @escaping () -> (), @ViewBuilder label: () -> Content) {
        
        self.action = action
        self.label = label()
    }
    
    let action: () -> ()
    let label: Content
    
    public var body: some View {
        
        Button(action: action, label: {
           label
        })
        #if os(watchOS)
        .buttonStyle(PlainButtonStyle())
        #else
        .buttonStyle(LUIButtonStyle())
        #endif
    }
}

public struct LUIButtonStyle: ButtonStyle {
    
    public init() {
    }
    
    @Environment(\.accessibilityShowButtonShapes)
    private var accessibilityShowButtonShapes
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
