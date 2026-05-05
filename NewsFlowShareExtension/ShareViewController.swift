import UIKit
import Social
import MobileCoreServices
import UniformTypeIdentifiers

// MARK: - Share View Controller

/// Share Extension that allows users to save article URLs from Safari or other apps.
/// Shares are handled by extracting the URL and passing it to the main app via a shared store.
final class ShareViewController: SLComposeServiceViewController {

    private var sharedURL: URL?

    override func isContentValid() -> Bool {
        true
    }

    override func didSelectPost() {
        guard let url = sharedURL else {
            extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        // Store the shared URL in shared UserDefaults for the main app to pick up
        let sharedDefaults = UserDefaults(suiteName: "group.burakbilgen.NewsFlow")
        var pendingURLs = sharedDefaults?.array(forKey: "pendingSharedURLs") as? [String] ?? []
        pendingURLs.append(url.absoluteString)
        sharedDefaults?.set(pendingURLs, forKey: "pendingSharedURLs")

        // Open the main app via URL scheme
        if let openURL = URL(string: "newsflow://article?url=\(url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")") {
            _ = openURL
        }

        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func configurationItems() -> [Any]! {
        []
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        placeholder = "Add a note (optional)"
        extractSharedURL()
    }

    // MARK: - Private

    private func extractSharedURL() {
        guard let extensionItems = extensionContext?.inputItems as? [NSExtensionItem] else { return }

        for item in extensionItems {
            guard let attachments = item.attachments else { continue }

            for attachment in attachments {
                if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] data, _ in
                        if let url = data as? URL {
                            DispatchQueue.main.async {
                                self?.sharedURL = url
                                self?.textView.text = url.absoluteString
                            }
                        }
                    }
                } else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] data, _ in
                        if let text = data as? String, let url = URL(string: text) {
                            DispatchQueue.main.async {
                                self?.sharedURL = url
                            }
                        }
                    }
                }
            }
        }
    }
}
