import SwiftUI
import Combine

// MARK: - Toast Style

enum ToastStyle {
    case error
    case success
    case info
    case warning

    var backgroundColor: Color {
        switch self {
        case .error: return Color(red: 0.85, green: 0.20, blue: 0.20)
        case .success: return Color(red: 0.20, green: 0.65, blue: 0.30)
        case .info: return Color(red: 0.15, green: 0.45, blue: 0.75)
        case .warning: return Color(red: 0.90, green: 0.55, blue: 0.10)
        }
    }

    var icon: String {
        switch self {
        case .error: return "xmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Toast Model

struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let style: ToastStyle
    let duration: TimeInterval
    let action: ToastAction?
    let onDismiss: (() -> Void)?

    static func == (lhs: Toast, rhs: Toast) -> Bool {
        lhs.id == rhs.id
    }
}

struct ToastAction {
    let title: String
    let handler: () -> Void
}

// MARK: - Toast Manager

/// Global toast manager with queue support.
/// Ensures only one toast is visible at a time.
@MainActor
final class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published private(set) var currentToast: Toast?
    private var queue: [Toast] = []
    private var dismissWorkItem: DispatchWorkItem?

    private init() {}

    func show(
        _ message: String,
        style: ToastStyle = .info,
        duration: TimeInterval = 3.0,
        action: ToastAction? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        let toast = Toast(
            message: message,
            style: style,
            duration: duration,
            action: action,
            onDismiss: onDismiss
        )

        if currentToast == nil {
            present(toast)
        } else {
            queue.append(toast)
        }
    }

    func dismiss() {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil

        withAnimation(.easeInOut(duration: 0.3)) {
            currentToast = nil
        }

        // Show next toast after dismissal animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.showNext()
        }
    }

    private func present(_ toast: Toast) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentToast = toast
        }

        let workItem = DispatchWorkItem { [weak self] in
            self?.dismiss()
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + toast.duration, execute: workItem)
    }

    private func showNext() {
        guard !queue.isEmpty else { return }
        let next = queue.removeFirst()
        present(next)
    }
}

// MARK: - Toast View

struct ToastView: View {
    let toast: Toast
    let onDismiss: () -> Void

    @State private var isVisible = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: toast.style.icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)

            Text(toast.message)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
                .lineLimit(3)

            Spacer()

            if let action = toast.action {
                Button {
                    action.handler()
                    onDismiss()
                } label: {
                    Text(action.title)
                        .font(.caption.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, AppSpacing.sm)
                        .padding(.vertical, AppSpacing.xxs)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.25))
                        )
                }
                .buttonStyle(.plain)
            }

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .fill(toast.style.backgroundColor)
                .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal, AppSpacing.md)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height < 0 {
                        dragOffset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height < -50 {
                        withAnimation(.easeOut(duration: 0.2)) {
                            dragOffset = -200
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            onDismiss()
                        }
                    } else {
                        withAnimation(.spring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                isVisible = true
            }
        }
    }
}

// MARK: - Toast Modifier

struct ToastModifier: ViewModifier {
    @StateObject private var manager = ToastManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            VStack {
                if let toast = manager.currentToast {
                    ToastView(toast: toast) {
                        manager.dismiss()
                    }
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                Spacer()
            }
            .padding(.top, AppSpacing.lg)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: manager.currentToast)
        }
    }
}

extension View {
    func toastOverlay() -> some View {
        modifier(ToastModifier())
    }
}
