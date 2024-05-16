//
//  ImageCardView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.07.22.
//

import SwiftUI

let formHeaderColor = Color.mainColor.opacity(0.6)


struct ImageCardGroupHeader: View {
    
    let name: String
    
    var body: some View {
        
        PlainImageCardGroupHeader(name: name)
            .padding(.horizontal, Constants.FormHorizontalPadding)
            .padding(.top, 30)
            .padding(.bottom, 12)
    }
}


struct PlainImageCardGroupHeader<Content: View>: View {
    let name: String
    let extraView: () -> Content
    
    init(name: String, extraView: @escaping () -> Content = {EmptyView()}) {
        self.name = name
        self.extraView = extraView
    }
    
    var body: some View {
            
            HStack {
                Text(name.localized())
                    .font(.footnote.weight(.medium))
                    .foregroundColor(.grayColor)
                    
                extraView()
                
                Spacer()
            }
            .padding(.horizontal, 5)
    }
}


struct ImageCardView: View {
    
    let card: ImageCard
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        VStack {
            ArticleImageView(name: card.imageName)
                .cornerRadius(10)
                .modifier(ShadowModifier())
            
            VStack(spacing: 0) {
                
                HStack {
                    Group {
                        Text(card.header.localized())
                            .bold()
                        
                        Image(systemName: "chevron.right")
                            .opacity(0.7)
                    }
                    .font(.system(.headline))
                    
                    
                    Spacer()
                }
                .padding(.vertical, 5)
                
                HStack {
                    Text(card.subHeader.localized())
                        .multilineTextAlignment(.leading)
                        .font(.system(.subheadline))
                        .opacity(0.7)
                    
                    Spacer()
                }
                .padding(.top, 1)
            }
            .foregroundColor(.mainColor)
            .padding(.horizontal, 5)
        }
    }
}


struct ArticleImageView: View {
    
    @Environment(\.colorScheme) var colorScheme
    let name: String
    
    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .padding(.horizontal, 30)
       
            .background(ZStack {
                Image(name)
                    .resizable()
                    .blur(radius: 30)
                    .scaledToFit()
                    .scaleEffect(4)
                    .clipped()
                    .allowsHitTesting(false)
            }.scaleEffect(x: 2)
            )
            .drawingGroup()
    }
}


struct NewImageCardView: View {
    
    let card: ImageCard
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
        VStack(spacing: 0) {
            
            ArticleImageView(name: card.imageName)
            
            
            VStack(spacing: 0) {
                
                HStack {
                    Text(card.header.localized())
                        .bold()
                        .multilineTextAlignment(.leading)
                        .font(.system(.caption))
                        .foregroundColor(.mainColor)
                        .opacity(0.7)
                    
                    Spacer()
                }
                .padding(.top, 7)
                .padding(.bottom, 2)
                
                HStack {
                    Text(card.subHeader.localized())
                        .bold()
                        .multilineTextAlignment(.leading)
                        .font(.system(.title3))
                        .foregroundColor(.mainColor)
                    
                    Spacer()
                }
                .padding(.top, 1)
            }
            .padding(.horizontal, 13)
            .padding(.top, 5)
            .padding(.bottom, 13)
        }
        .modifier(FormModifierNoPadding())
    }
}



struct Previews_ImageCardView_Previews: PreviewProvider {
    static var previews: some View {
        NewImageCardView(card: articles[2].card)
            .padding()
    }
}
