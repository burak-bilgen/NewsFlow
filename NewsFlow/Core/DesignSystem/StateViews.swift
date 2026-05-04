import SwiftUI

struct LoadingStateView: View {
    let text: String

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            ProgressView()
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct StateMessageView: View {
    let systemImage: String
    let title: String
    let message: String
    var retryTitle: String?
    var retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundColor(AppPalette.primaryRed)

            Text(title)
                .font(.title3.weight(.semibold))
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)

            if let retryTitle, let retryAction {
                Button(retryTitle, action: retryAction)
                    .buttonStyle(ReadingListButtonStyle())
                    .accessibilityIdentifier("state.retry.button")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppSpacing.xl)
    }
}
