import SwiftUI
import SwiftData

/// Browse logged tasting notes. New notes are created via the sensory-wheel editor.
struct TastingLogView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TastingNote.date, order: .reverse) private var notes: [TastingNote]

    @State private var showingEditor = false
    @State private var editing: TastingNote?

    var body: some View {
        NavigationStack {
            Group {
                if notes.isEmpty {
                    ContentUnavailableView(
                        "No tasting notes yet",
                        systemImage: "circle.hexagongrid",
                        description: Text("Tap + to log how a cup tasted using the flavour wheel.")
                    )
                } else {
                    List {
                        ForEach(notes) { note in
                            row(note)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editing = note
                                    showingEditor = true
                                }
                        }
                        .onDelete { offsets in
                            for i in offsets { modelContext.delete(notes[i]) }
                            try? modelContext.save()
                        }
                    }
                }
            }
            .navigationTitle("Tasting Log")
            .toolbar {
                ToolbarItem {
                    Button {
                        editing = nil
                        showingEditor = true
                    } label: {
                        Label("New Note", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                TastingNoteEditorView(note: editing) { result in
                    if editing == nil { modelContext.insert(result) }
                    try? modelContext.save()
                }
            }
        }
    }

    private func row(_ note: TastingNote) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(note.beanName ?? "Unknown bean").font(.body.weight(.semibold))
                Spacer()
                if note.rating > 0 {
                    HStack(spacing: 1) {
                        ForEach(0..<note.rating, id: \.self) { _ in
                            Image(systemName: "star.fill").imageScale(.small)
                        }
                    }
                    .foregroundStyle(.yellow)
                }
            }
            Text("\(note.drink.displayName) · \(note.date.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption).foregroundStyle(.secondary)
            if !note.descriptors.isEmpty {
                FlowLayout(spacing: 4) {
                    ForEach(note.descriptors, id: \.self) { d in
                        Text(d)
                            .font(.caption2)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(.background.tertiary, in: Capsule())
                    }
                }
            }
            if !note.freeText.isEmpty {
                Text(note.freeText).font(.caption).foregroundStyle(.secondary).lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    TastingLogView()
        .modelContainer(PreviewData.previewContainer())
        .frame(width: 700, height: 700)
}
