import UIKit
import RaceSyncAPI

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        if let url = connectionOptions.urlContexts.first?.url {
            DispatchQueue.main.async {
                DeepLinkURLHandler.shared.handle(url: url)
            }
        }
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        PushMessagesController.shared.preloadDeliveredNotifications()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        DeepLinkURLHandler.shared.handle(url: url)
    }

    func windowScene(_ windowScene: UIWindowScene,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return (UIApplication.shared.delegate as? AppDelegate)?.orientationLock ?? .portrait
    }
}
