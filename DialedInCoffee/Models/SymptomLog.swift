import Foundation
import SwiftData

@Model
public final class SymptomLog {
    @Attribute(.unique) public var id: UUID
    public var date: Date
    public var symptomsRaw: [String]
    public var drinkRaw: String
    public var beanName: String?
    public var note: String

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        symptoms: [Symptom],
        drink: DrinkType,
        beanName: String? = nil,
        note: String = ""
    ) {
        self.id = id
        self.date = date
        self.symptomsRaw = symptoms.map(\.rawValue)
        self.drinkRaw = drink.rawValue
        self.beanName = beanName
        self.note = note
    }

    public var symptoms: [Symptom] { symptomsRaw.compactMap(Symptom.init(rawValue:)) }
    public var drink: DrinkType { DrinkType(rawValue: drinkRaw) ?? .flatWhite }
}
