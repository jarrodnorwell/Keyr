//
//  SceneDelegate.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import OnboardingKit
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow? = nil
    
    var accountStore: AccountStore = .init()
    var onboardingModel: OnboardingModel? = nil
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }
        
        onboardingModel = .init(accountStore: accountStore, sceneDelegate: self)
        
        var configuration: UICollectionLayoutListConfiguration = .init(appearance: .insetGrouped)
        configuration.headerMode = .supplementary
        configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
            let copyAction: UIContextualAction = .init(style: .destructive, title: nil) { action, view, completed in
                UIPasteboard.general.string = self.accountStore.accounts[indexPath.item].code
                completed(true)
            }
            copyAction.backgroundColor = .systemIndigo
            copyAction.image = .init(systemName: "clipboard")
            
            let renameAction: UIContextualAction = .init(style: .normal, title: nil) { action, view, completed in
                guard let viewController = self.currentViewController() else {
                    completed(true)
                    return
                }
                
                let alertController: UIAlertController = .init(title: "Rename Account", message: "Enter a new name for this account",
                                                               preferredStyle: .alert)
                alertController.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in
                    completed(true)
                }))
                alertController.addAction(.init(title: "Rename", style: .default, handler: { _ in
                    guard let textFields = alertController.textFields, let textField = textFields.first,
                          let string = textField.text, !string.isEmpty else {
                        completed(true)
                        return
                    }
                    
                    self.accountStore.rename(at: indexPath.section, to: string)
                    completed(true)
                }))
                alertController.addTextField()
                viewController.present(alertController, animated: true)
            }
            renameAction.backgroundColor = .systemBlue
            renameAction.image = .init(systemName: "square.and.pencil")
            
            let removeAction: UIContextualAction = .init(style: .destructive, title: nil) { action, view, completed in
                self.accountStore.delete(at: indexPath.section)
                completed(true)
            }
            removeAction.image = .init(systemName: "minus.circle")
            
            return .init(actions: [removeAction, renameAction, copyAction])
        }
        
        let keyrController: KeyrController = .init(accountStore: accountStore,
                                                   UICollectionViewCompositionalLayout.list(using: configuration))
        accountStore.delegate = keyrController
        
        Task {
            guard let onboardingModel else {
                return
            }
            
            await onboardingModel.cameraAccess.checkAuthorisationStatus()
            UserDefaults.standard.set(await onboardingModel.cameraAccess.authorised,
                                      forKey: "keyr.1.0.cameraAccessGranted")
            
            let cameraAccessGranted: Bool = UserDefaults.standard.bool(forKey: "keyr.1.0.cameraAccessGranted")
            let onboardingComplete: Bool = UserDefaults.standard.bool(forKey: "keyr.1.0.onboardingComplete")
            
            window = .init(windowScene: windowScene)
            guard let window else {
                return
            }
            
            window.rootViewController = if cameraAccessGranted && onboardingComplete {
                UINavigationController(rootViewController: keyrController)
            } else {
                controller(onboardingModel, cameraAccessGranted, onboardingComplete)
            }
            window.tintColor = .systemYellow
            window.makeKeyAndVisible()
            
            await accountStore.load()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {}

    func sceneDidEnterBackground(_ scene: UIScene) {}
    
    func controller(_ onboardingModel: OnboardingModel, _ cameraAccessGranted: Bool, _ onboardingComplete: Bool) -> UIViewController {
        if !cameraAccessGranted && onboardingComplete {
            OnboardingController(configuration: .init(buttons: [
                .init(text: "Open Settings", handler: { button, controller in
                    guard let url: URL = .init(string: UIApplication.openDefaultApplicationsSettingsURLString),
                          UIApplication.shared.canOpenURL(url) else {
                        return
                    }
                    
                    UIApplication.shared.open(url)
                })
            ], colours: Color.vibrantOranges, image: .init(systemName: "gearshape.fill"),
                                                      text: "Access Denied",
                                                      secondaryText: "Access to the Camera has been denied and Keyr cannot function without it. Please go to the Settings app to allow access"))
        } else {
            OnboardingController(configuration: .init(buttons: [
                .init(text: "Continue", handler: { button, controller in
                    await onboardingModel.camera(controller: controller)
                })
            ], colours: Color.vibrantYellows, image: .init(systemName: "key.2.on.ring.fill")?
                .applyingSymbolConfiguration(.init(hierarchicalColor: .systemBackground)),
                                                      text: "Keyr",
                                                      secondaryText: "Beautifully designed, simple 2-factor authentication for all of your accounts"))
        }
    }
    
    func currentViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }),
              let rootViewController = window.rootViewController
        else {
            return nil
        }

        return topViewController(from: rootViewController)
    }

    private func topViewController(from rootViewController: UIViewController) -> UIViewController {
        if let presented = rootViewController.presentedViewController {
            return topViewController(from: presented)
        } else if let nav = rootViewController as? UINavigationController {
            return topViewController(from: nav.visibleViewController ?? nav)
        } else if let tab = rootViewController as? UITabBarController {
            return topViewController(from: tab.selectedViewController ?? tab)
        } else {
            return rootViewController
        }
    }
}
