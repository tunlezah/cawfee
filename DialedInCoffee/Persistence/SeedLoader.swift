import Foundation
import SwiftData
import OSLog

public enum SeedError: Error {
    case fileNotFound(String)
    case decodingFailed(String)
}

public enum SeedLoader {
    private static let log = Logger(subsystem: "coffee.dialedin", category: "SeedLoader")

    /// Load preferences (creating if needed) and seed beans on first launch.
    @MainActor
    public static func bootstrapIfNeeded(context: ModelContext, bundle: Bundle = .main) {
        seedWaterProfilesIfNeeded(context: context)
        seedMaintenanceTasksIfNeeded(context: context)

        let prefs = preferences(in: context)
        guard !prefs.hasSeededBeans else {
            log.debug("Beans already seeded, skipping.")
            return
        }
        do {
            let dtos = try loadBeanSeeds(bundle: bundle)
            for dto in dtos {
                let bean = BeanProfile(
                    slug: dto.slug,
                    name: dto.name,
                    roaster: dto.roaster,
                    roastLevel: dto.toRoastLevel(),
                    milkFriendly: dto.milkFriendly,
                    flavourNotes: dto.flavourNotes,
                    recommendedSettings: dto.toMachineSettings(),
                    notes: dto.notes ?? "",
                    isSeeded: true
                )
                context.insert(bean)
            }
            prefs.hasSeededBeans = true
            try context.save()
            log.debug("Seeded \(dtos.count, privacy: .public) beans.")
        } catch {
            log.error("Bean seed failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Seed default water profiles (incl. the local Canberra/ACT tap) once.
    @MainActor
    public static func seedWaterProfilesIfNeeded(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<WaterProfile>())) ?? []
        guard existing.isEmpty else { return }
        for profile in defaultWaterProfiles() { context.insert(profile) }
        try? context.save()
        log.debug("Seeded water profiles.")
    }

    /// Seed default espresso-machine maintenance tasks once.
    @MainActor
    public static func seedMaintenanceTasksIfNeeded(context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<MaintenanceTask>())) ?? []
        guard existing.isEmpty else { return }
        for task in defaultMaintenanceTasks() { context.insert(task) }
        try? context.save()
        log.debug("Seeded maintenance tasks.")
    }

    /// Canberra tap figures approximate Icon Water's published averages: soft,
    /// low-alkalinity water (great for the machine, can taste flat).
    static func defaultWaterProfiles() -> [WaterProfile] {
        [
            WaterProfile(
                name: "Canberra Tap (ACT)",
                detail: "Approx. Icon Water average — soft, low-bicarbonate.",
                calcium: 20, magnesium: 10, bicarbonate: 30, totalHardness: 55,
                isDefault: true, isSeeded: true, sortOrder: 0
            ),
            WaterProfile(
                name: "Third Wave Water (Espresso)",
                detail: "Distilled + TWW espresso mineral packet.",
                calcium: 50, magnesium: 18, bicarbonate: 50, totalHardness: 150,
                isDefault: false, isSeeded: true, sortOrder: 1
            ),
            WaterProfile(
                name: "SCA Target",
                detail: "Mid-point of SCA recommended brewing-water range.",
                calcium: 40, magnesium: 12, bicarbonate: 50, totalHardness: 100,
                isDefault: false, isSeeded: true, sortOrder: 2
            )
        ]
    }

    static func defaultMaintenanceTasks() -> [MaintenanceTask] {
        [
            MaintenanceTask(
                name: "Backflush (water)",
                detail: "Blind-basket backflush with water to clear the group.",
                symbolName: "arrow.triangle.2.circlepath",
                intervalDays: 3, intervalShots: 20, isSeeded: true, sortOrder: 0
            ),
            MaintenanceTask(
                name: "Backflush (detergent)",
                detail: "Backflush with espresso machine cleaner (e.g. Cafiza).",
                symbolName: "bubbles.and.sparkles",
                intervalDays: 14, intervalShots: 200, isSeeded: true, sortOrder: 1
            ),
            MaintenanceTask(
                name: "Descale",
                detail: "ACT water is soft, so descaling can be infrequent — but don't skip it.",
                symbolName: "drop.triangle",
                intervalDays: 120, isSeeded: true, sortOrder: 2
            ),
            MaintenanceTask(
                name: "Clean shower screen",
                detail: "Remove and scrub the group head shower screen.",
                symbolName: "shower",
                intervalDays: 14, isSeeded: true, sortOrder: 3
            ),
            MaintenanceTask(
                name: "Replace group gasket",
                detail: "Swap the portafilter gasket when it hardens or leaks.",
                symbolName: "circle.dashed",
                intervalDays: 365, isSeeded: true, sortOrder: 4
            ),
            MaintenanceTask(
                name: "Clean grinder burrs",
                detail: "Brush out fines and old grounds from the burrs and chute.",
                symbolName: "fan",
                intervalDays: 30, isSeeded: true, sortOrder: 5
            )
        ]
    }

    public static func loadBeanSeeds(bundle: Bundle = .main) throws -> [BeanSeedDTO] {
        guard let url = bundle.url(forResource: "beans", withExtension: "json") else {
            throw SeedError.fileNotFound("beans.json")
        }
        let data = try Data(contentsOf: url)
        do {
            let file = try JSONDecoder().decode(BeanSeedFile.self, from: data)
            return file.beans
        } catch {
            throw SeedError.decodingFailed("beans.json: \(error.localizedDescription)")
        }
    }

    /// Fetch (or create) the singleton preferences row.
    @MainActor
    public static func preferences(in context: ModelContext) -> UserPreferences {
        let fetch = FetchDescriptor<UserPreferences>(
            predicate: #Predicate { $0.singletonKey == "default" }
        )
        if let existing = try? context.fetch(fetch).first {
            return existing
        }
        let prefs = UserPreferences()
        context.insert(prefs)
        try? context.save()
        return prefs
    }
}
