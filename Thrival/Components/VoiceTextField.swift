import SwiftUI

struct VoiceTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var axis: Axis = .vertical
    var lineLimit: Int = 3

    @StateObject private var speechRecognizer = SpeechRecognizer()
    @State private var showingVoiceInput = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                        if !speechRecognizer.transcript.isEmpty {
                            if text.isEmpty {
                                text = speechRecognizer.transcript
                            } else {
                                text += " " + speechRecognizer.transcript
                            }
                        }
                    } else {
                        speechRecognizer.startRecording()
                    }
                } label: {
                    Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                        .foregroundStyle(speechRecognizer.isRecording ? .red : .accentColor)
                        .symbolEffect(.pulse, isActive: speechRecognizer.isRecording)
                }
                .disabled(!speechRecognizer.isAvailable)
            }

            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .lineLimit(lineLimit, reservesSpace: true)

            if speechRecognizer.isRecording {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("Listening...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !speechRecognizer.transcript.isEmpty {
                        Text("- \(speechRecognizer.transcript)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
    }
}

struct VoiceTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var minHeight: CGFloat = 80

    @StateObject private var speechRecognizer = SpeechRecognizer()

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    if speechRecognizer.isRecording {
                        speechRecognizer.stopRecording()
                        if !speechRecognizer.transcript.isEmpty {
                            if text.isEmpty {
                                text = speechRecognizer.transcript
                            } else {
                                text += " " + speechRecognizer.transcript
                            }
                        }
                    } else {
                        speechRecognizer.startRecording()
                    }
                } label: {
                    Image(systemName: speechRecognizer.isRecording ? "mic.fill" : "mic")
                        .foregroundStyle(speechRecognizer.isRecording ? .red : .accentColor)
                        .symbolEffect(.pulse, isActive: speechRecognizer.isRecording)
                }
                .disabled(!speechRecognizer.isAvailable)
            }

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 8)
                }

                TextEditor(text: $text)
                    .frame(minHeight: minHeight)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if speechRecognizer.isRecording {
                HStack {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("Listening...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        VoiceTextField(
            title: "Stress Triggers",
            placeholder: "What triggered stress today?",
            text: .constant("")
        )

        VoiceTextEditor(
            title: "Notes",
            placeholder: "Additional notes...",
            text: .constant("")
        )
    }
    .padding()
}
