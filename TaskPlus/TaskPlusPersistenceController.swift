import Foundation
import CoreData
import CloudKit

class TaskPlusPersistenceController: ObservableObject {
    static let shared = TaskPlusPersistenceController()
    
    let container: NSPersistentCloudKitContainer
    
    private init() {
        container = NSPersistentCloudKitContainer(name: "TaskPlus")
        
        // CloudKit同期の設定
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        // CloudKit同期を有効化
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // CloudKitコンテナの設定
        description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
            containerIdentifier: "iCloud.com.delmar.FocusPlus"
        )
        
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // CloudKit同期の監視を設定
        setupCloudKitSyncMonitoring()
    }
    
    // MARK: - CloudKit Sync Monitoring
    private func setupCloudKitSyncMonitoring() {
        // リモート変更通知の監視
        NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { _ in
            // リモート変更があった場合、UIを更新
            DispatchQueue.main.async {
                self.container.viewContext.refreshAllObjects()
            }
        }
        
        // CloudKitアカウント状態の監視
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.CKAccountChanged,
            object: nil,
            queue: .main
        ) { _ in
            // iCloudアカウントの状態が変更された場合の処理
            self.handleCloudKitAccountChange()
        }
    }
    
    private func handleCloudKitAccountChange() {
        // iCloudアカウントの状態を確認
        CKContainer.default().accountStatus { accountStatus, error in
            DispatchQueue.main.async {
                switch accountStatus {
                case .available:
                    print("TaskPlus CloudKit: iCloudアカウントが利用可能です")
                case .noAccount:
                    print("TaskPlus CloudKit: iCloudアカウントが設定されていません")
                case .restricted:
                    print("TaskPlus CloudKit: iCloudアカウントが制限されています")
                case .couldNotDetermine:
                    print("TaskPlus CloudKit: iCloudアカウントの状態を確認できません")
                case .temporarilyUnavailable:
                    print("TaskPlus CloudKit: iCloudアカウントが一時的に利用できません")
                @unknown default:
                    print("TaskPlus CloudKit: 不明なアカウント状態")
                }
            }
        }
    }
    
    // MARK: - Data Migration from Legacy Models
    func migrateFromLegacyModels() {
        // 一時的に無効化
        print("TaskPlus: レガシーデータ移行は一時的に無効化されています")
    }
    
    // MARK: - FocusPlus Integration
    func addFocusSessionFromFocusPlus(taskId: String, session: FocusSession) {
        // 一時的に無効化
        print("TaskPlus: FocusPlus統合は一時的に無効化されています")
    }
    
    // MARK: - Data Export for FocusPlus
    func exportDataForFocusPlus() -> Data? {
        // 一時的に無効化
        print("TaskPlus: データエクスポートは一時的に無効化されています")
        return nil
    }
}

// MARK: - Core Data Extensions
// 一時的に無効化
