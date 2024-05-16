//
//  CustomForm.swift
//  AirGuard
//
//  Created by Leon Böttger on 10.05.22.
//

import SwiftUI

public extension Color {
    static let indigo = Color(#colorLiteral(red: 0.3667442501, green: 0.422971189, blue: 0.9019283652, alpha: 1))
    
    static let mainColor = Color("MainColor")
    static let grayColor = Color.mainColor.opacity(0.6)
}


struct CustomFormBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(BackgroundColorView().ignoresSafeArea())
    }
}


struct BackgroundColorView: View {
    
    @Environment(\.sheetActive) var sheetActive
    
    var body: some View {
        (sheetActive ? Color.sheetBackground : Color.defaultBackground)
    }
}


public extension EnvironmentValues {
    var sheetActive: Bool {
        get { self[SheetActiveKey.self] }
        set { self[SheetActiveKey.self] = newValue }
    }
}


struct SheetActiveKey: EnvironmentKey {
    static let defaultValue = false
}


public struct CustomSection<Content: View, Content2: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    let headerExtraView: () -> Content2
    let header: String
    let footer: String
    let backgroundColor: Color?
    
    public init(header: String = "",
                footer: String = "",
                backgroundColor: Color? = nil,
                headerExtraView: @escaping () -> Content2 = {EmptyView()},
                @ViewBuilder content: @escaping () -> Content) {
        
        self.content = content()
        self.headerExtraView = headerExtraView
        self.header = header
        self.footer = footer
        self.backgroundColor = backgroundColor
    }
    
    
    public var body: some View {
        
        VStack {
            if(header != "") {
                PlainImageCardGroupHeader(name: header.localized()) {
                    headerExtraView()
                }
            }
            
            VStack(spacing: 0) {
                
                DividerView {
                    content
                }
            }
            .modifier(FormModifier(backgroundColor: backgroundColor))
            
            if(footer != ""){
                FooterView(text: footer)
            }
        }
#if !os(watchOS)
        .padding(.horizontal, Constants.FormHorizontalPadding)
        .padding(.top, 15)
#endif
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


struct FormModifier: ViewModifier {
    
    let backgroundColor: Color?
    
    init(backgroundColor: Color? = nil) {
        self.backgroundColor = backgroundColor
    }
    
    func body(content: Content) -> some View {
        content
            .padding(.horizontal)
            .modifier(FormModifierNoPadding(backgroundColor: backgroundColor))
    }
}


struct FormModifierNoPadding: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.sheetActive) var sheetActive
    let showShadow: Bool
    let backgroundColor: Color?
    
    init(showShadow: Bool = false, backgroundColor: Color? = nil) {
        self.showShadow = showShadow
        self.backgroundColor = backgroundColor
    }
    
    func body(content: Content) -> some View {
        content
            .background(getColor())
            .cornerRadius(20)
            .compositingGroup()
            .modifier(ShadowModifier(visible: showShadow))
    }
    
    func getColor() -> Color {
        if let backgroundColor = backgroundColor {
            return backgroundColor
        }
        if sheetActive {
            return Color.sheetForeground
        }
        return Color.defaultForeground
    }
}


struct ShadowModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let visible: Bool
    
    init(visible: Bool = true) {
        self.visible = visible
    }
    
    func body(content: Content) -> some View {
        if visible && colorScheme.isLight {
            content
                .shadow(color: Color.gray.opacity(0.25), radius: 2, x: 0, y: 1)
        }
        else {
            content
        }
    }
}


public struct FooterView: View {
    
    public init(text: String) {
        self.text = text
    }
    
    let text: String
    
    public var body: some View {
        
        HStack {
            Text(text.localized())
                .fixedSize(horizontal: false, vertical: true)
                .foregroundColor(.grayColor)
                .font(.system(.footnote))
                .lineSpacing(2)
                .padding(.top, 5)
            
            Spacer()
        }
        .padding(.horizontal)
    }
}


struct DividerView<Content: View>: View {
    var content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        _VariadicView.Tree(DividerLayout()) {
            content
        }
    }
    
    struct DividerLayout: _VariadicView_MultiViewRoot {
        
        @ViewBuilder
        func body(children: _VariadicView.Children) -> some View {
            
            let last = children.last?.id
            
            ForEach(children) { child in
                
                child
                
                if child.id != last {
                    Divider()
                }
            }
        }
    }
}


struct Previews_CustomForm_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
