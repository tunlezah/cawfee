import Foundation
import SwiftData
import OSLog

public enum ModelContainerFactory {
    private static let log = Logger(subsystem: "coffee.dialedin", category: "Persistence")

    public static let modelTypes: [any PersistentModel.Type] = [
        BeanProfile.self,
        Recipe.self,
        AdjustmentHistoryEntry.self,
        SymptomLog.self,
        UserPreferences.self,
        Shot.self,
        MaintenanceTask.self,
        WaterProfile.self,
        TastingNote.self,
    ]

    public static func makeShared() -> ModelContainer {
        do {
            let schema = Schema(modelTypes)
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            log.error("Failed to create persistent container, falling back to in-memory: \(error.localizedDescription, privacy: .public)")
            return makeInMemory()
        }
    }

    public static func makeInMemory() -> ModelContainer {
        // In-memory containers should never fail; if they do something is fundamentally wrong.
        let schema = Schema(modelTypes)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        return try! ModelContainer(for: schema, configurations: [config])
    }
}
