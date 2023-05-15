//
//  CaruselView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.07.22.
//

import SwiftUI

struct ArticlesCarusel: View {
    
    @State private var currentCard = 0
    
    let elems: [Article]
    let width: CGFloat
    
    var body: some View {
        
        let cutoff = 0.85
        let cardWidth = width * cutoff
        
        CarouselView(activeCard: $currentCard, count: elems.count, screenWidth: width, cutoff: cutoff) {
            HStack(alignment: .top, spacing: 0) {

                ForEach(elems) { elem in
                    NavigationLink {
                        ArticleView(article: elem)
                    } label: {
                        ImageCardView(card: elem.card)
                            .padding(.leading)
                            .frame(width: cardWidth)
                    }
                    .buttonStyle(PlainLinkStyle())
                }

            }.offset(x: -width*((1-cutoff)/2))
                .contentShape(Rectangle())
        }.frame(width: width)
    }
}


struct CarouselView<Content: View>: View {

    @ObservedObject var settings = Settings.sharedInstance
    
    private let content: () -> Content
    
    @State private var currentDrag: CGFloat = 0.0
    @Binding var currentIndex: Int
    @State private var calculatedOffset: CGFloat
    
    private let cardWidth: CGFloat
    private let cardCount: Int
    
    private let maxOffset: CGFloat
    
    init(activeCard: Binding<Int>, count: Int, screenWidth: CGFloat, cutoff: CGFloat, @ViewBuilder content: @escaping () -> Content) {

        self.cardWidth = screenWidth * cutoff
        self.cardCount = count
        self.maxOffset = cardWidth * CGFloat(cardCount) / 2 - cardWidth / 2

        self._calculatedOffset = .init(wrappedValue: self.maxOffset)
        self.content = content
        self._currentIndex = activeCard
    }
    
    var body: some View {
        
        let overshoot = abs(calculatedOffset) - maxOffset
        
        let xo = overshoot > 0 ?
        (calculatedOffset > 0 ?
         calculatedOffset - overshoot + overshoot/2:
            calculatedOffset + overshoot - overshoot/2) :
        calculatedOffset
        
        content()
        .offset(x: xo, y: 0)
        .animation(.spring(response: 0.4, dampingFraction: 1, blendDuration: 0.1), value: calculatedOffset)
        .highPriorityGesture(
            DragGesture()
                .onChanged { currentState in
                    self.calculateOffset(drag: currentState.translation.width)
                }
                .onEnded { value in
                    withAnimation(.spring()) {
                        self.handleDragEnd(translationWidth: value.translation.width)
                    }
                }
        )
        .onChange(of: settings.isBackground) { val in
            if val {
                self.handleDragEnd(translationWidth: 0)
            }
        }
    }
    
    /// stopped dragging, go to next card
    func handleDragEnd(translationWidth: CGFloat) {

        if translationWidth < -50 && currentIndex < cardCount - 1 {
            currentIndex += 1
        }
        if translationWidth > 50 && currentIndex != 0 {
            currentIndex -= 1
        }
        self.calculateOffset(drag: 0)
    }
    
    
    /// calculate offset for next card
    func calculateOffset(drag: CGFloat) {
        let activeOffset = maxOffset - (cardWidth * CGFloat(currentIndex))
        let nextOffset = maxOffset - (cardWidth * CGFloat(currentIndex + 1))
        calculatedOffset = activeOffset
        if activeOffset != nextOffset {
            calculatedOffset = activeOffset + drag
        }
    }
}


struct Previews_CaruselView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
        ArticlesCarusel(elems: Array(articles.dropFirst()), width: 300)
        Spacer()
        }
        .frame(maxWidth: .infinity)
            .modifier(CustomFormBackground())
    }
}
