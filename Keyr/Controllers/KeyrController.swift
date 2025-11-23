//
//  KeyrController.swift
//  Keyr
//
//  Created by Jarrod Norwell on 6/11/2025.
//

import UIKit
internal import Combine
import OnboardingKit

class KeyrController : UICollectionViewController {
    var dataSource: UICollectionViewDiffableDataSource<Account, Account>? = nil
    var snapshot: NSDiffableDataSourceSnapshot<Account, Account>? = nil
    
    var accountStore: AccountStore
    init(accountStore: AccountStore, _ collectionViewLayout: UICollectionViewCompositionalLayout) {
        self.accountStore = accountStore
        super.init(collectionViewLayout: collectionViewLayout)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let navigationController {
            navigationController.navigationBar.prefersLargeTitles = true
        }
        navigationItem.largeTitleDisplayMode = .inline
        navigationItem.style = .browser
        navigationItem.largeTitle = "Keyr"
        navigationItem.title = navigationItem.largeTitle
        navigationItem.largeSubtitle = "0 keys available"
        navigationItem.subtitle = navigationItem.largeSubtitle
        
        let plusEllipsisItemGroup: UIBarButtonItemGroup = .init(barButtonItems: [
            .init(systemItem: .add, menu: .init(preferredElementSize: .medium, children: [
                UIAction(title: "QR code", image: .init(systemName: "qrcode"), handler: { _ in
                    let viewController: QRScannerController = .init()
                    viewController.modalPresentationStyle = .fullScreen
                    viewController.codeFoundHandler = { string in
                        viewController.dismiss(animated: true) {
                            self.parseCode(string)
                        }
                    }
                    self.present(viewController, animated: true)
                }),
                UIAction(title: "Secret", image: .init(systemName: "rectangle.and.pencil.and.ellipsis"), handler: { _ in
                    let alertController: UIAlertController = .init(title: "Add Account", message: "Enter a secret provided by the service",
                                                                   preferredStyle: .alert)
                    alertController.addAction(.init(title: "Cancel", style: .cancel))
                    alertController.addAction(.init(title: "Add", style: .default) { _ in
                        guard let textFields = alertController.textFields, let textField = textFields.first,
                              let string = textField.text, !string.isEmpty else {
                            return
                        }
                        
                        self.parseCode(string)
                    })
                    alertController.addTextField()
                    alertController.preferredAction = alertController.actions.last
                    self.present(alertController, animated: true)
                })
            ]))
        ], representativeItem: nil)
        
        navigationItem.trailingItemGroups = [plusEllipsisItemGroup]
        view.backgroundColor = .systemBackground
        
        let headerRegistration: UICollectionView.SupplementaryRegistration<UICollectionViewListCell> = .init(elementKind: UICollectionView.elementKindSectionHeader) { cell, elementKind, indexPath in
            var contentConfiguration: UIListContentConfiguration = .extraProminentInsetGroupedHeader()
            if let dataSource = self.dataSource, let sectionIdentifier = dataSource.sectionIdentifier(for: indexPath.section) {
                contentConfiguration.text = sectionIdentifier.name
                contentConfiguration.secondaryText = "\(sectionIdentifier.digits) digits • \(sectionIdentifier.period) seconds • \(sectionIdentifier.algorithm.string)"
            }
            cell.contentConfiguration = contentConfiguration
        }
        
        let cellRegistration: UICollectionView.CellRegistration<UICollectionViewListCell, Account> = .init { cell, indexPath, itemIdentifier in
            var contentConfiguration: UIListContentConfiguration = .subtitleCell()
            Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                var code: String
                let date: Date = .init()
                do {
                    code = try TOTP.generate(secretBase32: itemIdentifier.secretBase32,
                                             digits: itemIdentifier.digits,
                                             time: date,
                                             period: itemIdentifier.period,
                                             algorithm: itemIdentifier.algorithm)
                } catch {
                    code = "Unknown"
                }
                
                contentConfiguration.text = code
                contentConfiguration.textProperties.font = .bold(.extraLargeTitle)
                contentConfiguration.secondaryText = itemIdentifier.issuer
                cell.contentConfiguration = contentConfiguration
                
                let elapsed = Int(date.timeIntervalSince1970) % itemIdentifier.period
                cell.accessories = [
                    .label(text: "\(itemIdentifier.period - elapsed)s", options: .init(font: .bold(.extraLargeTitle)))
                ]
            }
        }
        
        dataSource = .init(collectionView: collectionView) { collectionView, indexPath, itemIdentifier in
            collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
        }
        
        guard let dataSource else {
            return
        }
        
        dataSource.reorderingHandlers.canReorderItem = { _ in true }
        dataSource.reorderingHandlers.didReorder = { transation in
            self.accountStore.accounts = transation.finalSnapshot.itemIdentifiers
        }
        
        dataSource.supplementaryViewProvider = { collectionView, elementKind, indexPath in
            collectionView.dequeueConfiguredReusableSupplementary(using: headerRegistration, for: indexPath)
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
    
    func parseCode(_ code: String) {
        if !code.trimmingCharacters(in: .whitespacesAndNewlines).lowercased().hasPrefix("otpauth://") {
            let base32Regex = try! NSRegularExpression(pattern: "^[A-Z2-7\\s]+$", options: .caseInsensitive)
            let range = NSRange(location: 0, length: code.utf16.count)
            if base32Regex.firstMatch(in: code, options: [], range: range) != nil {
                let alertController: UIAlertController = .init(title: "Account Name",
                                                               message: "Enter a name for this account",
                                                               preferredStyle: .alert)
                alertController.addAction(.init(title: "Cancel", style: .cancel))
                alertController.addAction(.init(title: "Add", style: .default) { _ in
                    guard let textFields = alertController.textFields,
                          let textField = textFields.first,
                          let enteredName = textField.text, !enteredName.isEmpty else {
                        return
                    }
                    
                    let account: Account = .init(issuer: "Manual",
                                                 name: enteredName,
                                                 secretBase32: code.replacingOccurrences(of: " ", with: ""),
                                                 digits: 6,
                                                 period: 30,
                                                 algorithm: .sha1)
                    self.accountStore.add(account)
                })
                alertController.addTextField()
                alertController.preferredAction = alertController.actions.last
                present(alertController, animated: true)
                return
            } else {
                return
            }
        }
        
        guard let url: URL = .init(string: code),
              let components: URLComponents = .init(string: code),
              components.scheme == "otpauth",
              components.host == "totp" else {
            return
        }
        
        guard let queryItems: [URLQueryItem] = components.queryItems else {
            return
        }
        
        var namePart = url.path
        if namePart.hasPrefix("/") { namePart.removeFirst() }
        let label = namePart.removingPercentEncoding ?? namePart
        
        var secret: String?
        var issuer: String?
        var algorithm: String? = OTPAlgorithm.sha1.rawValue
        var digits: Int = 6
        var period: Int = 30
        
        for item in queryItems {
            switch item.name.lowercased() {
            case "secret":
                secret = item.value
            case "issuer":
                issuer = item.value
            case "algorithm":
                algorithm = item.value
            case "digits":
                if let value = item.value, let intValue = Int(value) {
                    digits = intValue
                }
            case "period":
                if let value = item.value, let intValue = Int(value) {
                    period = intValue
                }
            default:
                break
            }
        }
        
        var issuerFromLabel: String? = nil
        var nameOnly = label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Manual" : label
        if label.contains(":") {
            let parts = label.split(separator: ":", maxSplits: 1).map(String.init)
            issuerFromLabel = parts[0]
            nameOnly = parts[1]
        }
        let finalIssuer = issuer ?? issuerFromLabel
        
        guard let secret, let algorithm else {
            return
        }
        
        let inferredAlgorithm: OTPAlgorithm = switch algorithm {
        case "sha1": .sha1
        case "sha256": .sha256
        case "sha512": .sha512
        default: .sha1
        }
        
        if let finalIssuer, !finalIssuer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let account: Account = .init(issuer: finalIssuer,
                                         name: nameOnly,
                                         secretBase32: secret.replacingOccurrences(of: " ", with: ""),
                                         digits: digits,
                                         period: period,
                                         algorithm: inferredAlgorithm)
            accountStore.add(account)
        } else {
            let alertController: UIAlertController = .init(title: "Account Name", message: "Enter a name for this account",
                                                           preferredStyle: .alert)
            alertController.addAction(.init(title: "Cancel", style: .cancel))
            alertController.addAction(.init(title: "Add", style: .default) { _ in
                guard let textFields = alertController.textFields, let textField = textFields.first,
                      let string = textField.text, !string.isEmpty else {
                    return
                }
                
                let account: Account = .init(issuer: nameOnly,
                                             name: string,
                                             secretBase32: secret.replacingOccurrences(of: " ", with: ""),
                                             digits: digits,
                                             period: period,
                                             algorithm: inferredAlgorithm)
                
                self.accountStore.add(account)
            })
            alertController.addTextField()
            alertController.preferredAction = alertController.actions.last
            present(alertController, animated: true)
        }
    }
}

extension KeyrController : AccountStoreDelegate {
    func accountStoreDidUpdate(_ store: AccountStore) {
        
    }
    
    func accountStore(_ store: AccountStore, didLoadAccounts accounts: [Account]) {
        navigationItem.largeSubtitle = "\(accounts.count) key\(accounts.count == 1 ? "" : "s") available"
        navigationItem.subtitle = navigationItem.largeSubtitle
        
        snapshot = .init()
        guard let dataSource, var snapshot else {
            return
        }
        
        snapshot.appendSections(accounts)
        snapshot.sectionIdentifiers.forEach { account in
            snapshot.appendItems(accounts.filter { $0.id == account.id }, toSection: account)
        }
        Task {
            await dataSource.apply(snapshot)
        }
    }
    
    func accountStore(_ store: AccountStore, didAddAccount account: Account) {
        navigationItem.largeSubtitle = "\(store.accounts.count) key\(store.accounts.count == 1 ? "" : "s") available"
        navigationItem.subtitle = navigationItem.largeSubtitle
        
        guard let dataSource else {
            return
        }
        
        var snapshot = dataSource.snapshot()
        snapshot.appendSections([account])
        snapshot.appendItems([account], toSection: account)
        Task {
            await dataSource.apply(snapshot)
        }
    }
    
    func accountStore(_ store: AccountStore, didRenameAccount account: Account) {
        guard let dataSource else {
            return
        }
        
        var snapshot = dataSource.snapshot()
        snapshot.reloadSections([account])
        snapshot.reloadItems([account])
        Task {
            await dataSource.apply(snapshot)
        }
    }
    
    func accountStore(_ store: AccountStore, didRemoveAccount account: Account) {
        navigationItem.largeSubtitle = "\(store.accounts.count) key\(store.accounts.count == 1 ? "" : "s") available"
        navigationItem.subtitle = navigationItem.largeSubtitle
        
        guard let dataSource else {
            return
        }
        
        var snapshot = dataSource.snapshot()
        snapshot.deleteSections([account])
        snapshot.deleteItems([account])
        Task {
            await dataSource.apply(snapshot)
        }
    }
}
