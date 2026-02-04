import SwiftUI
import CoreData

struct MedicationsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(fetchRequest: Medication.fetchRequest(activeOnly: false))
    private var medications: FetchedResults<Medication>

    @State private var showingAddMedication = false
    @State private var medicationToEdit: Medication?

    var body: some View {
        NavigationStack {
            Group {
                if medications.isEmpty {
                    emptyState
                } else {
                    medicationList
                }
            }
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddMedication = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddMedication) {
                AddEditMedicationView(medication: nil)
            }
            .sheet(item: $medicationToEdit) { medication in
                AddEditMedicationView(medication: medication)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Medications", systemImage: "pills")
        } description: {
            Text("Add medications you want to track daily.")
        } actions: {
            Button("Add Medication") {
                showingAddMedication = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var medicationList: some View {
        List {
            Section {
                ForEach(medications.filter { $0.isActive }) { medication in
                    MedicationRow(medication: medication)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            medicationToEdit = medication
                        }
                }
                .onDelete { indexSet in
                    deleteMedications(at: indexSet, from: medications.filter { $0.isActive })
                }
            } header: {
                Text("Active")
            }

            let inactive = medications.filter { !$0.isActive }
            if !inactive.isEmpty {
                Section {
                    ForEach(inactive) { medication in
                        MedicationRow(medication: medication)
                            .opacity(0.6)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                medicationToEdit = medication
                            }
                    }
                    .onDelete { indexSet in
                        deleteMedications(at: indexSet, from: inactive)
                    }
                } header: {
                    Text("Inactive")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func deleteMedications(at offsets: IndexSet, from list: [Medication]) {
        for index in offsets {
            let medication = list[index]
            viewContext.delete(medication)
        }

        do {
            try viewContext.save()
        } catch {
            print("Error deleting medication: \(error)")
        }
    }
}

struct MedicationRow: View {
    let medication: Medication

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "pills.fill")
                .foregroundStyle(.accentColor)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(medication.name ?? "Unknown")
                    .font(.headline)

                HStack(spacing: 8) {
                    if let dosage = medication.formattedDosage, !dosage.isEmpty {
                        Text(dosage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(medication.frequencyEnum.shortLabel)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct AddEditMedicationView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let medication: Medication?

    @State private var name: String = ""
    @State private var defaultDosage: String = ""
    @State private var dosageUnit: String = "mg"
    @State private var frequency: MedicationFrequency = .daily
    @State private var notes: String = ""
    @State private var isActive: Bool = true

    private let dosageUnits = ["mg", "mcg", "g", "ml", "patch", "tablet", "capsule", ""]

    var isEditing: Bool {
        medication != nil
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Medication Details") {
                    TextField("Name", text: $name)

                    HStack {
                        TextField("Dosage", text: $defaultDosage)
                            .keyboardType(.decimalPad)

                        Picker("Unit", selection: $dosageUnit) {
                            ForEach(dosageUnits, id: \.self) { unit in
                                Text(unit.isEmpty ? "None" : unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Picker("Frequency", selection: $frequency) {
                        ForEach(MedicationFrequency.allCases) { freq in
                            Text(freq.rawValue).tag(freq)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional notes", text: $notes, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                if isEditing {
                    Section {
                        Toggle("Active", isOn: $isActive)
                    } footer: {
                        Text("Inactive medications won't appear in daily tracking.")
                    }
                }

                if !frequency.requiresDailyTracking {
                    Section {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundStyle(.blue)
                            Text("This medication has an N/A option for days when it's not scheduled.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Medication" : "Add Medication")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let medication {
                    name = medication.name ?? ""
                    defaultDosage = medication.defaultDosage ?? ""
                    dosageUnit = medication.dosageUnit ?? "mg"
                    frequency = medication.frequencyEnum
                    notes = medication.notes ?? ""
                    isActive = medication.isActive
                }
            }
        }
    }

    private func save() {
        let med = medication ?? Medication(context: viewContext)

        if medication == nil {
            med.id = UUID()
            med.createdAt = Date()
            med.sortOrder = 0
        }

        med.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        med.defaultDosage = defaultDosage.isEmpty ? nil : defaultDosage
        med.dosageUnit = dosageUnit.isEmpty ? nil : dosageUnit
        med.frequency = frequency.rawValue
        med.notes = notes.isEmpty ? nil : notes
        med.isActive = isActive

        do {
            try viewContext.save()
        } catch {
            print("Error saving medication: \(error)")
        }
    }
}

#Preview {
    MedicationsView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
