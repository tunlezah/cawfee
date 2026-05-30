import SwiftUI
import SwiftData

/// Create or edit a tasting note, including selecting descriptors from the
/// SCA-style sensory wheel and rating body / acidity / sweetness / bitterness.
struct TastingNoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: [SortDescriptor(\BeanProfile.roaster), SortDescriptor(\BeanProfile.name)])
    private var beans: [BeanProfile]

    let existing: TastingNote?
    let onSave: (TastingNote) -> Void

    @State private var beanSlug: String?
    @State private var drink: DrinkType
    @State private var descriptors: Set<String>
    @State private var body0: Int
    @State private var acidity: Int
    @State private var sweetness: Int
    @State private var bitterness: Int
    @State private var rating: Int
    @State private var freeText: String

    init(note: TastingNote?, onSave: @escaping (TastingNote) -> Void) {
        self.existing = note
        self.onSave = onSave
        _beanSlug = State(initialValue: note?.beanSlug)
        _drink = State(initialValue: note?.drink ?? .cappuccino)
        _descriptors = State(initialValue: Set(note?.descriptors ?? []))
        _body0 = State(initialValue: note?.body ?? 0)
        _acidity = State(initialValue: note?.acidity ?? 0)
        _sweetness = State(initialValue: note?.sweetness ?? 0)
        _bitterness = State(initialValue: note?.bitterness ?? 0)
        _rating = State(initialValue: note?.rating ?? 0)
        _freeText = State(initialValue: note?.freeText ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(existing == nil ? "New Tasting Note" : "Edit Tasting Note")
                .font(.title2.weight(.semibold))

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    SectionPanel("Cup", systemImage: "cup.and.saucer") {
                        Picker("Bean", selection: $beanSlug) {
                            Text("None").tag(String?.none)
                            ForEach(beans) { bean in
                                Text("\(bean.name) · \(bean.roaster)").tag(Optional(bean.slug))
                            }
                        }
                        Picker("Drink", selection: $drink) {
                            ForEach(DrinkType.allCases) { Text($0.displayName).tag($0) }
                        }
                    }

                    SectionPanel("Flavour wheel", systemImage: "circle.hexagongrid.fill") {
                        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                            ForEach(SensoryWheel.categories) { category in
                                VStack(alignment: .leading, spacing: 4) {
                                    Label(category.name, systemImage: category.symbolName)
                                        .font(.subheadline.weight(.semibold))
                                    FlowLayout(spacing: 6) {
                                        ForEach(category.descriptors, id: \.self) { d in
                                            descriptorChip(d)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    SectionPanel("Intensity", systemImage: "slider.horizontal.3") {
                        VStack(spacing: Theme.Spacing.sm) {
                            ratingRow("Body", $body0)
                            ratingRow("Acidity", $acidity)
                            ratingRow("Sweetness", $sweetness)
                            ratingRow("Bitterness", $bitterness)
                        }
                    }

                    SectionPanel("Overall", systemImage: "star") {
                        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                            starRow
                            TextField("Free notes", text: $freeText, axis: .vertical)
                                .lineLimit(2...5)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                }
            }

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                Button(existing == nil ? "Save" : "Update") { save() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(minWidth: 520, minHeight: 640)
    }

    private func descriptorChip(_ d: String) -> some View {
        let on = descriptors.contains(d)
        return Button {
            if on { descriptors.remove(d) } else { descriptors.insert(d) }
        } label: {
            Text(d)
                .font(.caption.weight(on ? .semibold : .regular))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(on ? AnyShapeStyle(.tint.opacity(0.25)) : AnyShapeStyle(.background.tertiary), in: Capsule())
                .overlay(Capsule().strokeBorder(on ? AnyShapeStyle(.tint) : AnyShapeStyle(.clear)))
        }
        .buttonStyle(.plain)
    }

    private func ratingRow(_ label: String, _ value: Binding<Int>) -> some View {
        HStack {
            Text(label).frame(width: 90, alignment: .leading)
            ForEach(1...5, id: \.self) { i in
                Circle()
                    .fill(i <= value.wrappedValue ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
                    .frame(width: 18, height: 18)
                    .onTapGesture { value.wrappedValue = (value.wrappedValue == i) ? 0 : i }
            }
            Spacer()
        }
    }

    private var starRow: some View {
        HStack(spacing: 4) {
            Text("Rating").frame(width: 90, alignment: .leading)
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= rating ? "star.fill" : "star")
                    .foregroundStyle(star <= rating ? .yellow : .secondary)
                    .onTapGesture { rating = (rating == star) ? 0 : star }
            }
        }
    }

    private func save() {
        let bean = beans.first { $0.slug == beanSlug }
        if let existing {
            existing.beanName = bean?.name
            existing.beanSlug = bean?.slug
            existing.drink = drink
            existing.descriptors = Array(descriptors).sorted()
            existing.body = body0
            existing.acidity = acidity
            existing.sweetness = sweetness
            existing.bitterness = bitterness
            existing.rating = rating
            existing.freeText = freeText
            onSave(existing)
        } else {
            let note = TastingNote(
                beanName: bean?.name,
                beanSlug: bean?.slug,
                drink: drink,
                descriptors: Array(descriptors).sorted(),
                body: body0, acidity: acidity, sweetness: sweetness, bitterness: bitterness,
                rating: rating, freeText: freeText
            )
            onSave(note)
        }
        dismiss()
    }
}
