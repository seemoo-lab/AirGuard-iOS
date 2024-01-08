//
//  CustomForm.swift
//  AirGuard
//
//  Created by Leon Böttger on 10.05.22.
//

import SwiftUI

struct CustomFormBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    func body(content: Content) -> some View {
        content
            .background(colorScheme.isLight ? Color("FormBackgroundLight").ignoresSafeArea() : Color.formDeepGray.ignoresSafeArea())
    }
}


struct CustomSection: View {
    @Environment(\.colorScheme) var colorScheme
    let inputViews: [AnyView]
    var header = ""
    var footer = ""
    
    let headerExtraView: AnyView
    
    init<V0: View>(header: String = "", footer: String = "", headerExtraView: AnyView = AnyView(EmptyView()),
                   @ViewBuilder content: @escaping () -> V0
    ) {
        let cv = content()
        inputViews = [AnyView(cv)]
        self.header = header
        self.footer = footer
        self.headerExtraView = headerExtraView
    }
    
    init<V0: View, V1: View>(header: String = "", footer: String = "", headerExtraView: AnyView = AnyView(EmptyView()),
                             @ViewBuilder content: @escaping () -> TupleView<(V0, V1)>
    ) {
        let cv = content().value
        
        inputViews = [AnyView(cv.0), AnyView(cv.1)]
        
        self.header = header
        self.footer = footer
        self.headerExtraView = headerExtraView
    }
    
    init<V0: View, V1: View, V2: View>(header: String = "", footer: String = "", headerExtraView: AnyView = AnyView(EmptyView()),
                                       @ViewBuilder content: @escaping () -> TupleView<(V0, V1, V2)>) {
        let cv = content().value
        inputViews = [AnyView(cv.0), AnyView(cv.1), AnyView(cv.2)]
        self.header = header
        self.footer = footer
        self.headerExtraView = headerExtraView
    }
    
    init<V0: View, V1: View, V2: View, V3: View>(header: String = "", footer: String = "", headerExtraView: AnyView = AnyView(EmptyView()),
                                                 @ViewBuilder content: @escaping () -> TupleView<(V0, V1, V2, V3)>) {
        let cv = content().value
        inputViews = [AnyView(cv.0), AnyView(cv.1), AnyView(cv.2), AnyView(cv.3)]
        self.header = header
        self.footer = footer
        self.headerExtraView = headerExtraView
    }
    
    init<V0: View, V1: View, V2: View, V3: View, V4: View>(header: String = "", footer: String = "", headerExtraView: AnyView = AnyView(EmptyView()),
                                                           @ViewBuilder content: @escaping () -> TupleView<(V0, V1, V2, V3, V4)>) {
        let cv = content().value
        inputViews = [AnyView(cv.0), AnyView(cv.1), AnyView(cv.2), AnyView(cv.3), AnyView(cv.4)]
        self.header = header
        self.footer = footer
        self.headerExtraView = headerExtraView
    }
    
    
    var body: some View {
        VStack{
            if(header != "") {
                
                PlainImageCardGroupHeader(name: header.localized(), extraView: headerExtraView)
            }
            
            VStack(spacing: 0) {
                ForEach(0 ..< inputViews.count, id: \.self) { index in
                    self.inputViews[index]
                    
                    if(index != inputViews.count - 1) {
                        CustomDivider()
                    }
                }
                
            }
            .modifier(FormModifier())
            
            
            if(footer != ""){
                HStack {
                    
                    Footer(text: footer)
                    
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
}

struct Footer: View {
    let text: String
    
    var body: some View {
        Text(text.localized())
            .fixedSize(horizontal: false, vertical: true)
            .font(.system(.footnote))
            .lineSpacing(2)
            .padding(.top, 5)
            .foregroundColor(Color.init(#colorLiteral(red: 0.4768142104, green: 0.4786779284, blue: 0.5020056367, alpha: 1)).opacity(0.9))
    }
}


struct CustomDivider: View {
    
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(.gray)
            .opacity(0.2)
    }
}


struct FormModifier: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal)
            .modifier(FormModifierNoPadding())
    }
}


struct FormModifierNoPadding: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let showShadow: Bool
    
    init(showShadow: Bool = true) {
        self.showShadow = showShadow
    }
    
    func body(content: Content) -> some View {
        content
            .background(colorScheme.isLight ? Color.white : Color.formGray)
            .cornerRadius(25)
            .compositingGroup()
            .modifier(ShadowModifier(visible: showShadow))
    }
}


struct ShadowModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let visible: Bool
    
    init(visible: Bool = true) {
        self.visible = visible
    }
    
    func body(content: Content) -> some View {
        content
            .shadow(color: Color.gray.opacity(colorScheme.isLight ? 0.15 : 0), radius: visible ? 4 : 0, x: 0, y: 1)
    }
}


struct Previews_CustomForm_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
