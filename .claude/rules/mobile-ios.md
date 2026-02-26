---
paths:
  - "**/*.swift"
  - "**/*.xib"
  - "**/*.storyboard"
  - "**/ios/**"
---
When working with iOS code:
- Use SwiftUI for new views, UIKit only for legacy
- Follow Apple Human Interface Guidelines
- Use Combine or async/await for async operations
- Use @Observable macro (iOS 17+) over ObservableObject
- Implement proper memory management (weak references for delegates)
- Handle all app lifecycle states
- Support Dynamic Type for accessibility
