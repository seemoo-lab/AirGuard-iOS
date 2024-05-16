//
//  LUILink.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 25.03.24.
//

import SwiftUI

public struct LUILink<Content1: View, Content2: View>: View {
    
    public init(style: LinkStyle = .Default,
                destination: Content1,
                isActive: Binding<Bool>? = nil,
                @ViewBuilder label: () -> Content2 = {EmptyView()}) {
        
        self.destination = destination
        self.label = label()
        self.style = style
     
        if let isActive = isActive {
            self._isActive = isActive
            self.supportsIsActive = true
        }
        else {
            self._isActive = .constant(false)
            self.supportsIsActive = false
        }
    }
    
    let destination: Content1
    let label: Content2
    let style: LinkStyle
    
    @Binding var isActive: Bool
    let supportsIsActive: Bool
    @Environment(\.sheetActive) private var sheetActive
    
    public var body: some View {
        
        if(supportsIsActive) {
            NavigationLink(destination: destination
                .environment(\.sheetActive, sheetActive), isActive: $isActive) {
                label
            }
            .modifier(LinkStyleModifier(style: style))
        }
        else {
            NavigationLink(destination: destination.environment(\.sheetActive, sheetActive), label: {
                label
            })
            .modifier(LinkStyleModifier(style: style))
        }
    }
}


struct LinkStyleModifier: ViewModifier {
    
    let style: LinkStyle
    
    func body(content: Content) -> some View {
        if style == .Plain {
            content.buttonStyle(PlainLinkStyle())
        }
        else {
            content.buttonStyle(LUIButtonStyle())
        }
    }
}


public enum LinkStyle {
    case Plain
    case Default
}
