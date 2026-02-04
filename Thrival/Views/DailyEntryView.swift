import SwiftUI

struct DailyEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: DailyEntryViewModel

    @State private var showingSaveConfirmation = false
    @State private var expandedSections: Set<String> = ["medications", "sleep", "anxiety"]
    @State private var showingMedicationSettings = false

    init() {
        _viewModel = StateObject(wrappedValue: DailyEntryViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Date Header
                    dateHeader

                    // Quick Entry Sections
                    medicationsSection
                    sleepSection
                    anxietySection
                    focusSection
                    fitnessSection
                    nutritionSection
                    generalSection

                    // Save Button
                    saveButton
                        .padding(.top, 8)
                        .padding(.bottom, 32)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Daily Check-in")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if viewModel.isEditing {
                        Text("Editing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                    }
                }
            }
            .sheet(isPresented: $showingMedicationSettings) {
                MedicationsView()
                    .environment(\.managedObjectContext, viewContext)
                    .onDisappear {
                        viewModel.loadMedications()
                    }
            }
        }
        .sensoryFeedback(.success, trigger: showingSaveConfirmation)
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        VStack(spacing: 4) {
            Text(viewModel.dayOfWeek)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(viewModel.formattedDate)
                .font(.title2)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Medications Section

    private var medicationsSection: some View {
        CollapsibleSection(
            title: "Medications",
            icon: "pills.fill",
            isExpanded: expandedSections.contains("medications")
        ) {
            expandedSections.formSymmetricDifference(["medications"])
        } content: {
            VStack(spacing: 16) {
                if viewModel.hasMedications {
                    ForEach(viewModel.medications) { medication in
                        MedicationEntryRow(
                            medication: medication,
                            logState: viewModel.medicationLog(for: medication)
                        )

                        if medication != viewModel.medications.last {
                            Divider()
                        }
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "pills")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)

                        Text("No medications added")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Button("Add Medications") {
                            showingMedicationSettings = true
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                if viewModel.hasMedications {
                    Button {
                        showingMedicationSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "gear")
                            Text("Manage Medications")
                        }
                        .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
            }
        }
    }

    // MARK: - Sleep Section

    private var sleepSection: some View {
        CollapsibleSection(
            title: "Sleep",
            icon: "bed.double.fill",
            isExpanded: expandedSections.contains("sleep")
        ) {
            expandedSections.formSymmetricDifference(["sleep"])
        } content: {
            VStack(spacing: 16) {
                // Hours slept
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Hours slept")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f hrs", viewModel.hoursSlept))
                            .font(.headline)
                    }
                    Slider(value: $viewModel.hoursSlept, in: 0...14, step: 0.5)
                        .tint(.accentColor)
                }

                // Sleep quality
                RatingSlider(
                    title: "Sleep quality",
                    value: $viewModel.sleepQuality,
                    range: 1...5,
                    lowLabel: "Poor",
                    highLabel: "Excellent"
                )

                // Toggles
                HStack {
                    Toggle("Racing thoughts", isOn: $viewModel.racingThoughts)
                        .toggleStyle(.button)
                        .tint(viewModel.racingThoughts ? .orange : .gray)

                    Spacer()

                    Toggle("Weird dreams", isOn: $viewModel.weirdDreams)
                        .toggleStyle(.button)
                        .tint(viewModel.weirdDreams ? .purple : .gray)
                }
                .font(.subheadline)
            }
        }
    }

    // MARK: - Anxiety Section

    private var anxietySection: some View {
        CollapsibleSection(
            title: "Stress & Anxiety",
            icon: "heart.text.square.fill",
            isExpanded: expandedSections.contains("anxiety")
        ) {
            expandedSections.formSymmetricDifference(["anxiety"])
        } content: {
            VStack(spacing: 16) {
                CompactRatingSlider(title: "Morning", value: $viewModel.morningAnxiety, range: 0...10)
                CompactRatingSlider(title: "Afternoon", value: $viewModel.afternoonAnxiety, range: 0...10)
                CompactRatingSlider(title: "Evening", value: $viewModel.eveningAnxiety, range: 0...10)

                VoiceTextField(
                    title: "Stress triggers",
                    placeholder: "What triggered stress today?",
                    text: $viewModel.stressTriggers
                )

                VoiceTextField(
                    title: "Physical symptoms",
                    placeholder: "Any physical symptoms? (headache, tension, etc.)",
                    text: $viewModel.physicalSymptoms
                )
            }
        }
    }

    // MARK: - Focus Section

    private var focusSection: some View {
        CollapsibleSection(
            title: "Focus & Functioning",
            icon: "brain.head.profile",
            isExpanded: expandedSections.contains("focus")
        ) {
            expandedSections.formSymmetricDifference(["focus"])
        } content: {
            VStack(spacing: 16) {
                RatingSlider(
                    title: "Brain fog",
                    value: $viewModel.brainFog,
                    range: 0...5,
                    lowLabel: "Clear",
                    highLabel: "Foggy"
                )

                RatingSlider(
                    title: "Forgetfulness",
                    value: $viewModel.forgetfulness,
                    range: 0...5,
                    lowLabel: "Sharp",
                    highLabel: "Forgetful"
                )

                VoiceTextField(
                    title: "Examples",
                    placeholder: "Examples of forgetfulness...",
                    text: $viewModel.forgetfulnessExamples
                )
            }
        }
    }

    // MARK: - Fitness Section

    private var fitnessSection: some View {
        CollapsibleSection(
            title: "Fitness & Activity",
            icon: "figure.run",
            isExpanded: expandedSections.contains("fitness")
        ) {
            expandedSections.formSymmetricDifference(["fitness"])
        } content: {
            VStack(spacing: 16) {
                Toggle("Physically active today", isOn: $viewModel.physicallyActive)
                    .tint(.accentColor)

                if viewModel.physicallyActive {
                    TextField("Activity type", text: $viewModel.activityType)
                        .textFieldStyle(.roundedBorder)

                    TextField("Duration", text: $viewModel.activityDuration)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
    }

    // MARK: - Nutrition Section

    private var nutritionSection: some View {
        CollapsibleSection(
            title: "Nutrition",
            icon: "fork.knife",
            isExpanded: expandedSections.contains("nutrition")
        ) {
            expandedSections.formSymmetricDifference(["nutrition"])
        } content: {
            VStack(spacing: 16) {
                Stepper("Meals: \(viewModel.mealsCount)", value: $viewModel.mealsCount, in: 0...6)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Food quality")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Picker("Food quality", selection: $viewModel.foodQuality) {
                        ForEach(FoodQuality.allCases) { quality in
                            Text("\(quality.emoji) \(quality.rawValue)").tag(quality)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    // MARK: - General Section

    private var generalSection: some View {
        CollapsibleSection(
            title: "General",
            icon: "note.text",
            isExpanded: expandedSections.contains("general")
        ) {
            expandedSections.formSymmetricDifference(["general"])
        } content: {
            VStack(spacing: 16) {
                VoiceTextField(
                    title: "Overall mood",
                    placeholder: "How are you feeling overall?",
                    text: $viewModel.overallMood
                )

                VoiceTextEditor(
                    title: "Other notes",
                    placeholder: "Anything else to note...",
                    text: $viewModel.otherNotes
                )
            }
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button {
            viewModel.save()
            showingSaveConfirmation = true

            // Reset confirmation after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showingSaveConfirmation = false
            }
        } label: {
            HStack {
                Image(systemName: showingSaveConfirmation ? "checkmark.circle.fill" : "square.and.arrow.down.fill")
                Text(showingSaveConfirmation ? "Saved!" : (viewModel.isEditing ? "Update Entry" : "Save Entry"))
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(showingSaveConfirmation ? Color.green : Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .animation(.easeInOut, value: showingSaveConfirmation)
    }
}

// MARK: - Medication Entry Row

struct MedicationEntryRow: View {
    let medication: Medication
    @Binding var logState: MedicationLogState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with name and status picker
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(medication.name ?? "Unknown")
                        .font(.headline)

                    if !medication.formattedDosage.isEmpty {
                        Text(medication.formattedDosage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(medication.frequencyEnum.shortLabel)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }

                Spacer()

                // Status picker
                statusPicker
            }

            // Expanded details when taken
            if logState.status == .taken {
                VStack(spacing: 12) {
                    HStack {
                        Text("Dosage:")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        TextField("Dosage", text: $logState.dosage)
                            .textFieldStyle(.roundedBorder)
                            .font(.subheadline)
                    }

                    DatePicker(
                        "Time taken",
                        selection: Binding(
                            get: { logState.timeTaken ?? Date() },
                            set: { logState.timeTaken = $0 }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .font(.subheadline)
                }
                .padding(.leading, 4)
            }
        }
    }

    private var statusPicker: some View {
        HStack(spacing: 8) {
            StatusButton(
                icon: "checkmark.circle.fill",
                label: "Taken",
                isSelected: logState.status == .taken,
                color: .green
            ) {
                logState.status = .taken
                if logState.timeTaken == nil {
                    logState.timeTaken = Date()
                }
            }

            StatusButton(
                icon: "xmark.circle.fill",
                label: "Skip",
                isSelected: logState.status == .skipped,
                color: .red
            ) {
                logState.status = .skipped
            }

            if !medication.frequencyEnum.requiresDailyTracking {
                StatusButton(
                    icon: "minus.circle.fill",
                    label: "N/A",
                    isSelected: logState.status == .notApplicable,
                    color: .gray
                ) {
                    logState.status = .notApplicable
                }
            }
        }
    }
}

struct StatusButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: isSelected ? icon : icon.replacingOccurrences(of: ".fill", with: ""))
                    .font(.title3)
                    .foregroundStyle(isSelected ? color : .secondary)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? color : .secondary)
            }
            .frame(minWidth: 50)
            .padding(.vertical, 6)
            .padding(.horizontal, 8)
            .background(isSelected ? color.opacity(0.15) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Collapsible Section

struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    let isExpanded: Bool
    let toggle: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggle) {
                HStack {
                    Image(systemName: icon)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24)

                    Text(title)
                        .font(.headline)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if isExpanded {
                content()
                    .padding()
                    .background(Color(.systemGray6).opacity(0.5))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.top, 1)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

#Preview {
    DailyEntryView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
