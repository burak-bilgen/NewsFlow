# NewsApto Privacy Policy

**Last updated: May 22, 2026**

## Summary

NewsApto does not collect, store, or share any personal data. The app is designed with privacy as a fundamental principle.

## Data Collection

NewsApto collects **no personal information**. Specifically:

- **No account system** — No registration, no login, no email address
- **No analytics** — No tracking SDKs, no crash reporters, no telemetry
- **No ads** — No advertising networks, no ad trackers
- **No third-party SDKs** — The app uses 100% native Apple frameworks
- **No data sharing** — Nothing is sent to any server except API requests to news sources

## API Requests

The app fetches news articles by making requests to the following public APIs:
- NewsAPI (newsapi.org)
- The Guardian Open Platform (open-platform.theguardian.com)
- New York Times Article Search API (api.nytimes.com)
- GNews (gnews.io)
- NewsData.io (newsdata.io)
- HackerNews (hacker-news.firebaseio.com)

These requests are made directly from your device. API keys are bundled with the app and used solely for authentication. No additional data is sent with these requests.

## Local Storage

The following data is stored locally on your device and never transmitted:

- **Reading list** — Articles you save are stored in Core Data on-device
- **Image cache** — Downloaded article images are cached for performance
- **User preferences** — Category filters, notification settings, and read article tracking are stored in UserDefaults
- **Read articles tracker** — A local record of which articles you've viewed

## Notifications

If you grant notification permission, NewsApto may send local notifications for breaking news. No push notification infrastructure is used — all notifications are generated locally on your device.

## Data Deletion

Since no personal data is collected or stored server-side, there is nothing to delete. To clear local app data:
1. Go to Settings → Clear Cache in NewsApto
2. Or delete and reinstall the app

## Children's Privacy

NewsApto does not knowingly collect any data from children. The app is safe for all ages.

## Changes to This Policy

If this policy changes, the "Last updated" date at the top will be revised.

## Contact

For questions about this privacy policy, open an issue at:
https://github.com/burak-bilgen/NewsApto/issues
