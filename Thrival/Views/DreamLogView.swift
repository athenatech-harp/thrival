import SwiftUI
import CoreData

struct DreamLogView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        fetchRequest: DreamLog.recentDreamsFetchRequest(limit: 100),
        animation: .default
    )
    private var dreams: FetchedResults<DreamLog>

    @State private var showingAddDream = false
    @State private var selectedDream: DreamLog?

    var body: some View {
        NavigationStack {
            Group {
                if dreams.isEmpty {
                    emptyState
                } else {
                    dreamList
                }
            }
            .navigationTitle("Dream Log")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddDream = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddDream) {
                AddDreamView()
            }
            .sheet(item: $selectedDream) { dream in
                DreamDetailView(dream: dream)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Dreams Logged", systemImage: "moon.stars")
        } description: {
            Text("Tap the + button to log a dream.")
        } actions: {
            Button("Add Dream") {
                showingAddDream = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var dreamList: some View {
        List {
            ForEach(dreams) { dream in
                DreamRow(dream: dream)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDream = dream
                    }
            }
            .onDelete(perform: deleteDreams)
        }
        .listStyle(.insetGrouped)
    }

    private func deleteDreams(at offsets: IndexSet) {
        for index in offsets {
            let dream = dreams[index]
            viewContext.delete(dream)
        }

        do {
            try viewContext.save()
        } catch {
            print("Error deleting dream: \(error)")
        }
    }
}

struct DreamRow: View {
    let dream: DreamLog

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "moon.stars.fill")
                    .foregroundStyle(.purple)
                Text(dream.formattedDate)
                    .font(.headline)
                Spacer()
            }

            if let description = dream.dreamDescription, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            if let triggers = dream.possibleTriggers, !triggers.isEmpty {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                    Text(triggers)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddDreamView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel: DreamLogViewModel

    init() {
        _viewModel = StateObject(wrappedValue: DreamLogViewModel(context: PersistenceController.shared.container.viewContext))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $viewModel.date, displayedComponents: .date)
                }

                Section("Dream Description") {
                    VoiceTextEditor(
                        title: "",
                        placeholder: "Describe your dream...",
                        text: $viewModel.dreamDescription,
                        minHeight: 120
                    )
                }

                Section("Possible Triggers") {
                    VoiceTextField(
                        title: "",
                        placeholder: "What might have caused this dream?",
                        text: $viewModel.possibleTriggers
                    )
                }
            }
            .navigationTitle("Log Dream")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        viewModel.save()
                        dismiss()
                    }
                    .disabled(!viewModel.isValid)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct DreamDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let dream: DreamLog

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Date
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundStyle(.accentColor)
                        Text(dream.date?.formatted(date: .complete, time: .omitted) ?? "Unknown date")
                            .font(.headline)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Dream", systemImage: "moon.stars.fill")
                            .font(.headline)
                            .foregroundStyle(.purple)

                        Text(dream.dreamDescription ?? "No description")
                            .font(.body)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Triggers
                    if let triggers = dream.possibleTriggers, !triggers.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Possible Triggers", systemImage: "lightbulb.fill")
                                .font(.headline)
                                .foregroundStyle(.yellow)

                            Text(triggers)
                                .font(.body)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .navigationTitle("Dream Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    DreamLogView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
