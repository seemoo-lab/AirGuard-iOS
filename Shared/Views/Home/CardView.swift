//
//  CardView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 24.06.22.
//

import SwiftUI

struct CardView<Content: View>: View {
    
    let backgroundColor: Color
    let title: String
    let titleSymbol: String
    let subView: () -> Content
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        VStack {
            HStack {
                Text(title.localized())
                    .bold()

                Spacer()
                
                Image(systemName: titleSymbol)

            }   .font(.system(.title))
            
            Separator()
                .padding(.bottom, 5)
     
            
            subView()
        }
        .padding()
        .foregroundColor(backgroundColor == .white ? .gray : .white)
        .background(
            ZStack {
                backgroundColor
                LinearGradient(colors: [.clear, .white.opacity(0.15)], startPoint: .bottom, endPoint: .top)
            }
                .cornerRadius(20))
        .compositingGroup()
        .shadow(color: Color.gray.opacity(colorScheme.isLight ? 0.05 : 0), radius: 7, x: 3, y: 3)
        .padding(.horizontal, Constants.FormHorizontalPadding)
        .padding(.top)
        
    }
}


struct CardSubView: View {
    
    let symbol: String
    let text: String
    
    var body: some View {
      
        HStack {
            
            Image(systemName: symbol)
             
                .font(.system(size: 20, weight: .medium, design: .default))
                .frame(width: 25, height: 20)
            
            Text(text.localized())
                .multilineTextAlignment(.leading)
            
            Spacer()
            
        }
    }
}


struct Separator: View {
    
    var body: some View {
        Rectangle()
            .frame(height: 2)
    }
}


struct Previews_CardView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
