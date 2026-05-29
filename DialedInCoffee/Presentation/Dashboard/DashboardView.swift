import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var recipes: [Recipe]
    @Query(sort: \AdjustmentHistoryEntry.date, order: .reverse) private var history: [AdjustmentHistoryEntry]
    @Query private var beans: [BeanProfile]

    private var columns: [GridItem] {
        [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                heroHeader

                LazyVGrid(columns: columns, spacing: 16) {
                    DashboardCard(title: "Last good recipe", symbol: "star.fill") {
                        if let lastGood = recipes.first(where: { $0.isLastGood }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(lastGood.name)
                                    .font(.title3.weight(.semibold))
                                Text("\(lastGood.drink.displayName) · Grinder \(lastGood.grinder) · Strength \(lastGood.strength) · \(lastGood.volumeML)ml")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                if let bean = lastGood.bean {
                                    Text("\(bean.roaster) — \(bean.name)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            Text("Mark a recipe as 'last good' from the Recipes tab.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    DashboardCard(title: "Most recent adjustment", symbol: "clock.arrow.circlepath") {
                        if let last = history.first {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(parameterLabel(last))
                                    .font(.title3.weight(.semibold))
                                Text(last.rationale)
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }
                        } else {
                            Text("No adjustments logged yet.")
                                .foregroundStyle(.secondary)
                        }
                    }

                    DashboardCard(title: "Beans loaded", symbol: "leaf") {
                        Text("\(beans.count) beans across \(uniqueRoasters) roasters.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }

                    DashboardCard(title: "Australian style reminder", symbol: "cup.and.saucer.fill") {
                        Text("Aim for normal temperature, ~35ml volume, medium roast. Silky milk, not airy foam.")
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(Theme.Spacing.lg)
            .frame(maxWidth: 1200, alignment: .leading)
        }
        .navigationTitle("Dashboard")
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Welcome back")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Dial in your next cup.")
                .font(.system(size: 32, weight: .semibold, design: .default))
        }
    }

    private var uniqueRoasters: Int {
        Set(beans.map(\.roaster)).count
    }

    private func parameterLabel(_ entry: AdjustmentHistoryEntry) -> String {
        switch entry.primaryParameter {
        case .grinder: return "Grinder \(entry.beforeGrinder) → \(entry.afterGrinder)"
        case .strength: return "Strength \(entry.beforeStrength) → \(entry.afterStrength)"
        case .volume: return "Volume \(entry.beforeVolumeML) → \(entry.afterVolumeML) ml"
        case .milkDuration: return "Milk \(entry.beforeMilkSeconds) → \(entry.afterMilkSeconds) s"
        case .temperature: return "Temp \(entry.beforeTemperatureRaw) → \(entry.afterTemperatureRaw)"
        case .beans: return "Bean change suggested"
        }
    }
}

#Preview("Dashboard — Light") {
    DashboardView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 900, height: 700)
        .preferredColorScheme(.light)
}

#Preview("Dashboard — Dark") {
    DashboardView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 900, height: 700)
        .preferredColorScheme(.dark)
}
