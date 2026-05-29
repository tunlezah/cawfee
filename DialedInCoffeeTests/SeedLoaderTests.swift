import XCTest
import SwiftData
@testable import DialedInCoffee

@MainActor
final class SeedLoaderTests: XCTestCase {
    func testBundledBeansJSONDecodes() throws {
        // The Resources/Seed/beans.json file is bundled with the test target.
        let dtos = try SeedLoader.loadBeanSeeds(bundle: .main)
        XCTAssertFalse(dtos.isEmpty, "Expected seed beans to be present in bundle.")
        let slugs = Set(dtos.map(\.slug))
        XCTAssertEqual(slugs.count, dtos.count, "Slugs must be unique.")
    }

    func testSeedIsIdempotent() throws {
        let schema = Schema(ModelContainerFactory.modelTypes)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [config])
        let ctx = container.mainContext
        SeedLoader.bootstrapIfNeeded(context: ctx)
        let first = try ctx.fetch(FetchDescriptor<BeanProfile>()).count
        SeedLoader.bootstrapIfNeeded(context: ctx)
        let second = try ctx.fetch(FetchDescriptor<BeanProfile>()).count
        XCTAssertEqual(first, second, "Re-running seed must not duplicate beans.")
    }
}
