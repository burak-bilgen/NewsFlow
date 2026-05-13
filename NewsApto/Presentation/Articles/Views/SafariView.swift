import SafariServices
import SwiftUI

/// Wraps SFSafariViewController for SwiftUI presentation.
/// Opens the article's original URL in an in-app browser.
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
