//
//  OnboardingModel.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import OnboardingKit
import SwiftUI
import UIKit

actor OnboardingModel {
    var cameraAccess: CameraAccess = .init()
    
    var accountStore: AccountStore
    var sceneDelegate: SceneDelegate
    init(accountStore: AccountStore, sceneDelegate: SceneDelegate) {
        self.accountStore = accountStore
        self.sceneDelegate = sceneDelegate
    }
    
    @MainActor
    func camera(controller: UIViewController) async {
        let buttons: [OnboardingController.Onboarding.Button.Configuration] = [
            .init(text: "Continue", handler: { button, controller in
                let result: Bool = await self.cameraAccess.authorise()
                
                UserDefaults.standard.set(result,
                                          forKey: "keyr.1.0.cameraAccessGranted")
                UserDefaults.standard.set(true,
                                          forKey: "keyr.1.0.onboardingComplete")
                
                if result {
                    var configuration: UICollectionLayoutListConfiguration = .init(appearance: .insetGrouped)
                    configuration.headerMode = .supplementary
                    configuration.trailingSwipeActionsConfigurationProvider = { indexPath in
                        let copyAction: UIContextualAction = .init(style: .destructive, title: nil) { action, view, completed in
                            Task {
                                UIPasteboard.general.string = await self.accountStore.accounts[indexPath.item].code
                            }
                            completed(true)
                        }
                        copyAction.backgroundColor = .systemIndigo
                        copyAction.image = .init(systemName: "clipboard")
                        
                        let renameAction: UIContextualAction = .init(style: .normal, title: nil) { action, view, completed in
                            Task {
                                guard let viewController = await self.sceneDelegate.currentViewController() else {
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
                                    
                                    Task {
                                        await self.accountStore.rename(at: indexPath.section, to: string)
                                    }
                                    completed(true)
                                }))
                                alertController.addTextField()
                                viewController.present(alertController, animated: true)
                            }
                        }
                        renameAction.backgroundColor = .systemBlue
                        renameAction.image = .init(systemName: "square.and.pencil")
                        
                        let removeAction: UIContextualAction = .init(style: .destructive, title: nil) { action, view, completed in
                            Task {
                                await self.accountStore.delete(at: indexPath.section)
                            }
                            completed(true)
                        }
                        removeAction.image = .init(systemName: "minus.circle")
                        
                        return .init(actions: [removeAction, renameAction, copyAction])
                    }
                    
                    let keyrController: KeyrController = .init(accountStore: await self.accountStore,
                                                               UICollectionViewCompositionalLayout.list(using: configuration))
                    await self.accountStore.delegate = keyrController
                    
                    let viewController: UINavigationController = .init(rootViewController: keyrController)
                    viewController.modalPresentationStyle = .fullScreen
                    controller.present(viewController, animated: true)
                    
                    await self.accountStore.load()
                } else {
                    await self.settings(controller: controller)
                }
            })
        ]
        
        let cameraController: OnboardingController = .init(configuration: .init(buttons: buttons,
                                                                                colours: Color.vibrantGreens,
                                                                                image: .init(systemName: "camera.fill"),
                                                                                text: "Camera",
                                                                                secondaryText: "Keyr requires access to the Camera to capture QR codes for automatic information input",
                                                                                tertiaryText: "You can change this option later in the Settings app"))
        cameraController.modalPresentationStyle = .fullScreen
        controller.present(cameraController, animated: true)
    }
    
    @MainActor
    func settings(controller: UIViewController) async {
        let buttons: [OnboardingController.Onboarding.Button.Configuration] = [
            .init(text: "Open Settings", handler: { button, controller in
                guard let url: URL = .init(string: UIApplication.openDefaultApplicationsSettingsURLString),
                      UIApplication.shared.canOpenURL(url) else {
                    return
                }
                
                UIApplication.shared.open(url)
            })
        ]
        
        let openSettingsController: OnboardingController = .init(configuration: .init(buttons: buttons,
                                                                                      colours: Color.vibrantOranges,
                                                                                      image: .init(systemName: "gearshape.fill"),
                                                                                      text: "Access Denied",
                                                                                      secondaryText: "Access to the Camera has been denied and Keyr cannot function without it. Please go to the Settings app to allow access"))
        openSettingsController.modalPresentationStyle = .fullScreen
        controller.present(openSettingsController, animated: true)
    }
}
