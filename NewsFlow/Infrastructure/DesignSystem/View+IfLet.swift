import SwiftUI

// MARK: - Optional View Extensions

extension View {
    @ViewBuilder
    func ifLet<T, Content: View>(_ value: T?, transform: (Self, T) -> Content) -> some View {
        if let value {
            transform(self, value)
        } else {
            self
        }
    }

    @ViewBuilder
    func ifLet<T, U, Content: View>(_ value1: T?, _ value2: U?, transform: (Self, T, U) -> Content) -> some View {
        if let value1, let value2 {
            transform(self, value1, value2)
        } else {
            self
        }
    }
}
