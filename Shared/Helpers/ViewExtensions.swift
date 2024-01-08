//
//  ViewExtensions.swift
//  AirGuard
//
//  Created by Leon Böttger on 02.05.22.
//

import SwiftUI


extension ColorScheme {
    
    /// Returns if current color scheme is set to light.
    var isLight: Bool {
        self == ColorScheme.light
    }
}


/// Gets the begin and end string to make text bold in SwiftUI. Only works with iOS 15 and up.
func getBoldString() -> String {
    if #available(iOS 15.0, *) {
        return "**"
    } else {
        // iOS 14 did not support markdown
        return ""
    }
}


/// Button with only text
struct PlainLinkStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}


/// Returns the OS name
func getOSName() -> String {
    #if targetEnvironment(macCatalyst)
    return "macOS"
    #elseif os(watchOS)
    return WKInterfaceDevice.current().systemName
    #else
    return UIDevice.current.systemName
    #endif
}


extension UIImage {
    
    /// Resizes an UIImage to a certain size
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}


/// Returns true if current device is an iPad
func isiPad() -> Bool {
#if !os(watchOS)
    let device = UIDevice.current
    
    let iPad = device.model == "iPad"
    
    return iPad
    
#else
    return false
#endif
}


/// SwiftUI wrapper for UIKit Blur
struct Blur: UIViewRepresentable {
    var style: UIBlurEffect.Style = .systemUltraThinMaterial
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}


extension String {
    
    /// Returns the localized version of the current string.
    func localized() -> String {
        let localizedString = NSLocalizedString(self, comment: "")
        return localizedString
    }
    
    @available(iOS 15.0, *)
    func localizedMarkdown() -> AttributedString {
        let localizedString = NSLocalizedString(self, comment: "")
        let attributedString = try? AttributedString(markdown: localizedString, options: AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: true,
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        ))
        return attributedString ?? AttributedString(localizedString)
    }
}


extension Color {
    static var formLightGray = Color(#colorLiteral(red: 0.9490311742, green: 0.9487944245, blue: 0.9704338908, alpha: 1))
    static var formDeepGray = Color(#colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1098039216, alpha: 1))
    static var formGray = Color(#colorLiteral(red: 0.1725719571, green: 0.1724473834, blue: 0.1811259687, alpha: 1))
}


/// Centers the text and reduces opacity
struct TextCenterModifier: ViewModifier {
    
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .multilineTextAlignment(.center)
    }
}


/// Reduces opacity
struct OpacityModifier: ViewModifier {
    
    @Environment(\.colorScheme) var colorScheme
    let darkModeAsWell: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(colorScheme.isLight || darkModeAsWell ? 0.7 : 1)
    }
}


extension View {
    
    /// Centers the text and reduces opacity
    func centered() -> some View {
        modifier(TextCenterModifier())
    }
    
    /// Reduces opacity
    func lowerOpacity(darkModeAsWell: Bool = false) -> some View {
        modifier(OpacityModifier(darkModeAsWell: darkModeAsWell))
    }
}


extension View {
    
    /// Transforms a view into a large, colored button
    func customButton(colors: [Color]) -> ModifiedContent<Self, ButtonModifier> {
        return modifier(ButtonModifier(colors: colors))
    }
}


/// Transforms a view into a large, colored button
struct ButtonModifier: ViewModifier {
    
    var colors: [Color]
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .font(.headline)
            .padding()
            .frame(minWidth: 0, maxWidth: 320, alignment: .center)
            .background(getGradient(colors: colors).cornerRadius(20))
    }
}


extension View {
    
    /// Applies a gradient to the current view
    public func gradientForeground(gradient: LinearGradient) -> some View {
        self.overlay(gradient)
            .mask(self)
    }
}


/// Creates a `LinearGradient` from the colors provided
func getGradient(colors: [Color]) -> LinearGradient {
    return LinearGradient(gradient: .init(colors: colors), startPoint: .bottomLeading, endPoint: .topTrailing)
}


extension Text {
    
    /// Font used for introducation header
    func customTitleText() -> Text {
        self
            .fontWeight(.heavy)
            .font(.system(size: 36))
    }
    
    /// creates the default`LargeTitle` font
    func largeTitle() -> Text {
        self
            .bold()
            .font(.largeTitle)
    }
}

private struct SafeAreaInsetsKey: EnvironmentKey {
    
    /// returns the EdgeInsets for the current view
    static var defaultValue: EdgeInsets {
        (UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.safeAreaInsets ?? .zero).insets
    }
}

extension EnvironmentValues {

    /// Property to access the safeAreaInsets from any view.
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

private extension UIEdgeInsets {
    
    /// returns the UIEdgeInsets for the current view
    var insets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
