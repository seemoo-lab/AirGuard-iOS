//
//  ArticleView.swift
//  AirGuard (iOS)
//
//  Created by Leon Böttger on 01.07.22.
//

import SwiftUI

struct ArticleView : View {
    
    let article: Article
    
    var body: some View {
        
        GeometryReader { geo in
            
            let padding: CGFloat = 20
            let width = min(Constants.maxWidth, geo.size.width) - padding
            
            NavigationSubView() {
                
                Group {
                    
                    HStack {
                        Text(article.card.header.localized())
                            .bold()
                            .font(.system(size: 25))
                            .foregroundColor(Color("DarkBlue"))
                        
                        Spacer()
                    }.padding(.top)
                    
                    
                    HStack {
                        Text(String(format: "article_info".localized(), article.author, article.minRead.description))
                        
                        Spacer()
                    }.opacity(0.5)
                        .padding(.vertical, 8)
                        .padding(.bottom, 6)
                    
                    
                    VStack(spacing: 0) {
                        
                        ArticleImageView(name: article.card.imageName)
                        
                        if #available(iOS 15.0, *) {
                            Text(article.usesMarkdown ? article.text.localizedMarkdown() : AttributedString(article.text.localized())  )
                                .fixedSize(horizontal: false, vertical: true)
                                .lowerOpacity(darkModeAsWell: true)
                                .lineSpacing(7)
                                .padding(.vertical)
                                .padding(.horizontal, 15)
                        }else {
                            Text(article.text.localized())
                                .fixedSize(horizontal: false, vertical: true)
                                .lowerOpacity(darkModeAsWell: true)
                                .lineSpacing(7)
                                .padding(.vertical)
                                .padding(.horizontal, 15)
                        }
                    }
                    .modifier(FormModifierNoPadding())
                    
                    PlainImageCardGroupHeader(name: "more_articles")
                        .padding(.top, 30)
                        .padding(.bottom, 12)
                    
                }
                .padding(.horizontal)
                
                
                ArticlesCarusel(elems: articles.filter({$0.id != article.id}), width: width)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .modifier(GoToRootModifier(view: .HomeView))
    }
}


struct GoToRootModifier: ViewModifier {
    
    let view: Tabs
    
    @Environment(\.presentationMode) private var presentationMode
    @ObservedObject private var settings = Settings.sharedInstance
    
    func body(content: Content) -> some View {
        content
            .onChange(of: settings.goToRoot) { _ in
                if(settings.goToRootTab == view) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
    }
}


struct Previews_ArticleView_Previews: PreviewProvider {
    static var previews: some View {
        ArticleView(article: articles.first!)
    }
}
