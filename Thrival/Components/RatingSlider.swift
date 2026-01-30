import SwiftUI

struct RatingSlider: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var showLabels: Bool = true
    var lowLabel: String = "Low"
    var highLabel: String = "High"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .frame(minWidth: 30)
            }

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .tint(.accentColor)

            if showLabels {
                HStack {
                    Text(lowLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(highLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct CompactRatingSlider: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Slider(
                value: Binding(
                    get: { Double(value) },
                    set: { value = Int($0) }
                ),
                in: Double(range.lowerBound)...Double(range.upperBound),
                step: 1
            )
            .frame(maxWidth: 150)
            .tint(.accentColor)

            Text("\(value)")
                .font(.headline)
                .monospacedDigit()
                .frame(width: 30)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RatingSlider(
            title: "Morning Anxiety",
            value: .constant(5),
            range: 0...10,
            lowLabel: "Calm",
            highLabel: "Anxious"
        )

        CompactRatingSlider(
            title: "Brain Fog",
            value: .constant(2),
            range: 0...5
        )
    }
    .padding()
}
