import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var recipe: Recipe
    @State private var isEditing: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                header

                SectionPanel("Machine settings", systemImage: "slider.horizontal.3") {
                    Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 6) {
                        gridRow("Drink", recipe.drink.displayName)
                        gridRow("Milk", recipe.milkKind.displayName)
                        gridRow("Grinder", "\(recipe.grinder) / 7")
                        gridRow("Strength", "\(recipe.strength) / 10")
                        gridRow("Volume", "\(recipe.volumeML) ml")
                        if recipe.drink.isMilkBased {
                            gridRow("Milk time", "\(recipe.milkSeconds) s")
                        }
                        gridRow("Temperature", recipe.temperature.displayName)
                    }
                }

                if let bean = recipe.bean {
                    SectionPanel("Bean", systemImage: "leaf") {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bean.name)
                                .font(.body.weight(.semibold))
                            Text(bean.roaster)
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                SectionPanel("Notes", systemImage: "note.text") {
                    TextEditor(text: $recipe.notes)
                        .frame(minHeight: 100)
                        .font(.body)
                }

                HStack(spacing: 12) {
                    Toggle("Favourite", isOn: $recipe.isFavourite)
                    Toggle("Mark as last good", isOn: $recipe.isLastGood)
                }
                .toggleStyle(.switch)
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle(recipe.name)
        .toolbar {
            ToolbarItem {
                Button {
                    isEditing = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $isEditing) {
            let beans = (try? modelContext.fetch(FetchDescriptor<BeanProfile>())) ?? []
            RecipeEditorView(recipe: recipe, beans: beans) { _ in
                try? modelContext.save()
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(recipe.drink.displayName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(recipe.name)
                .font(.largeTitle.weight(.semibold))
        }
    }

    @ViewBuilder
    private func gridRow(_ label: String, _ value: String) -> some View {
        GridRow {
            Text(label).foregroundStyle(.secondary)
            Text(value).monospacedDigit()
        }
    }
}
