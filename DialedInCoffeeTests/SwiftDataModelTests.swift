import XCTest
import SwiftData
@testable import DialedInCoffee

@MainActor
final class SwiftDataModelTests: XCTestCase {
    func makeContainer() throws -> ModelContainer {
        let schema = Schema(ModelContainerFactory.modelTypes)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    func testInsertAndFetchBean() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let bean = BeanProfile(
            slug: "test-bean",
            name: "Test",
            roaster: "Test Roaster",
            roastLevel: .medium,
            milkFriendly: true,
            flavourNotes: ["chocolate"],
            recommendedSettings: MachineSettings()
        )
        ctx.insert(bean)
        try ctx.save()
        let fetched = try ctx.fetch(FetchDescriptor<BeanProfile>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.slug, "test-bean")
    }

    func testRecipeBeanRelationshipInverse() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let bean = BeanProfile(
            slug: "rel-bean",
            name: "Rel",
            roaster: "Test",
            roastLevel: .medium,
            milkFriendly: true,
            flavourNotes: [],
            recommendedSettings: MachineSettings()
        )
        ctx.insert(bean)
        let recipe = Recipe(name: "R1", drink: .flatWhite, settings: MachineSettings(), bean: bean)
        ctx.insert(recipe)
        try ctx.save()
        XCTAssertEqual(bean.recipes.count, 1)
        XCTAssertEqual(bean.recipes.first?.name, "R1")
    }

    func testHistoryEntryRoundTrip() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let before = MachineSettings(grinder: 5)
        let after = MachineSettings(grinder: 4)
        let entry = AdjustmentHistoryEntry(
            drink: .flatWhite,
            beanName: "Reservoir",
            symptoms: [.tooBitter],
            before: before,
            after: after,
            primaryParameter: .grinder,
            outcome: .better,
            rationale: "test",
            confidence: 0.7
        )
        ctx.insert(entry)
        try ctx.save()
        let fetched = try ctx.fetch(FetchDescriptor<AdjustmentHistoryEntry>())
        XCTAssertEqual(fetched.count, 1)
        XCTAssertEqual(fetched.first?.beforeSettings.grinder, 5)
        XCTAssertEqual(fetched.first?.afterSettings.grinder, 4)
        XCTAssertEqual(fetched.first?.symptoms, [.tooBitter])
    }

    func testUserPreferencesSingleton() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let p1 = SeedLoader.preferences(in: ctx)
        let p2 = SeedLoader.preferences(in: ctx)
        XCTAssertEqual(p1.singletonKey, p2.singletonKey)
    }
}
