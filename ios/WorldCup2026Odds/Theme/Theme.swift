import SwiftUI

enum Theme {
    static let home = Color("HomeAccent")
    static let draw = Color("DrawAccent")
    static let away = Color("AwayAccent")

    static let s1: CGFloat = 4
    static let s2: CGFloat = 8
    static let s3: CGFloat = 12
    static let s4: CGFloat = 16
    static let s5: CGFloat = 24

    static let cardRadius: CGFloat = 16
}

extension Font {
    static let pctLabel = Font.system(.caption, design: .rounded).weight(.semibold)
}
