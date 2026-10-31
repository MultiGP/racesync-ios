import SwiftUI

@main
struct ZippyQApp: App {

    var body: some Scene {
        WindowGroup {
            ZippyQRootView()
        }
    }
}

private struct ZippyQRootView: View {

    var body: some View {
        Color(uiColor: .systemBackground)
            .ignoresSafeArea()
    }
}
