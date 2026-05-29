import SwiftUI
import SwiftData

struct BeansListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\BeanProfile.roaster), SortDescriptor(\BeanProfile.name)])
    private var beans: [BeanProfile]

    @State private var selected: BeanProfile?
    @State private var searchText: String = ""
    @State private var showingEditor: Bool = false

    var body: some View {
        NavigationStack {
            HSplitView {
                list
                    .frame(minWidth: 280)
                if let selected {
                    BeanDetailView(bean: selected)
                        .frame(minWidth: 360)
                } else {
                    ContentUnavailableView("Select a bean", systemImage: "leaf", description: Text("Choose a roast on the left to view details."))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Beans")
            .toolbar {
                ToolbarItem {
                    Button {
                        showingEditor = true
                    } label: {
                        Label("New Bean", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                BeanEditorView(bean: nil) { newBean in
                    modelContext.insert(newBean)
                    try? modelContext.save()
                    selected = newBean
                }
            }
            .searchable(text: $searchText, prompt: "Search roasters or beans")
        }
    }

    private var filtered: [BeanProfile] {
        guard !searchText.isEmpty else { return beans }
        let q = searchText.lowercased()
        return beans.filter {
            $0.name.lowercased().contains(q) || $0.roaster.lowercased().contains(q)
        }
    }

    private var list: some View {
        List(selection: $selected) {
            ForEach(groupedByRoaster, id: \.roaster) { group in
                Section(group.roaster) {
                    ForEach(group.beans) { bean in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bean.name)
                            HStack(spacing: 6) {
                                Text(bean.roastLevel.displayName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if bean.milkFriendly {
                                    Image(systemName: "drop.fill")
                                        .imageScale(.small)
                                        .foregroundStyle(.secondary)
                                }
                                if bean.roastDate != nil {
                                    FreshnessBadge(freshness: bean.freshness(), compact: true)
                                }
                            }
                        }
                        .tag(bean)
                    }
                }
            }
        }
    }

    private struct Group {
        let roaster: String
        let beans: [BeanProfile]
    }

    private var groupedByRoaster: [Group] {
        let dict = Dictionary(grouping: filtered, by: { $0.roaster })
        return dict.keys.sorted().map { roaster in
            Group(roaster: roaster, beans: dict[roaster]!.sorted { $0.name < $1.name })
        }
    }
}

#Preview {
    BeansListView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 900, height: 600)
}
