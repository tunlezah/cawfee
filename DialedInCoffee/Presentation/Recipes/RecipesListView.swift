import SwiftUI
import SwiftData

struct RecipesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.createdAt, order: .reverse)
    private var recipes: [Recipe]
    @Query(sort: \BeanProfile.name) private var beans: [BeanProfile]

    @State private var selected: Recipe?
    @State private var showingEditor: Bool = false

    var body: some View {
        NavigationStack {
            HSplitView {
                list
                    .frame(minWidth: 280)
                if let selected {
                    RecipeDetailView(recipe: selected)
                        .frame(minWidth: 360)
                } else {
                    ContentUnavailableView("Select a recipe", systemImage: "book.closed", description: Text("Saved recipes appear on the left."))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Recipes")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("New Recipe", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                RecipeEditorView(recipe: nil, beans: beans) { recipe in
                    modelContext.insert(recipe)
                    try? modelContext.save()
                    selected = recipe
                }
            }
        }
    }

    private var list: some View {
        List(selection: $selected) {
            if recipes.isEmpty {
                Text("No recipes yet — save one from Fix My Coffee.")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
            ForEach(recipes) { recipe in
                row(recipe).tag(recipe)
            }
            .onDelete { offsets in
                for i in offsets {
                    modelContext.delete(recipes[i])
                }
                try? modelContext.save()
            }
        }
    }

    private func row(_ recipe: Recipe) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 6) {
                if recipe.isFavourite {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                        .imageScale(.small)
                }
                Text(recipe.name)
                if recipe.isLastGood {
                    Text("LAST GOOD")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.2), in: Capsule())
                        .foregroundStyle(.green)
                }
            }
            HStack(spacing: 6) {
                Text(recipe.drink.displayName)
                Text("•")
                Text("Grinder \(recipe.grinder) · Strength \(recipe.strength) · \(recipe.volumeML)ml")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    RecipesListView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 900, height: 600)
}
