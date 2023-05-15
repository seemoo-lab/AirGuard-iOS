//
//  NavigationSubView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 24.10.22.
//

import SwiftUI

struct NavigationSubView<Content: View>: View {
    let content: Content
    let spacing: CGFloat
    
    init(spacing: CGFloat = 0, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.spacing = spacing
    }
    
    var body: some View {
        
        ScrollView(showsIndicators: false) {
            
            VStack(spacing: spacing) {
                
                content
                
            }.padding(.bottom, 30)
                .frame(maxWidth: Constants.maxWidth)
                .frame(maxWidth: .infinity)
        }
        .modifier(CustomFormBackground())
    }
}
