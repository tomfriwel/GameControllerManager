import SwiftUI

struct ButtonHistoryView: View {
    let buttonHistory: [(button: String, timestamp: Date, duration: TimeInterval?)]

    var body: some View {
        VStack {
            Text("Button History")
                .font(.headline)
            List(buttonHistory, id: \.timestamp) { record in
                HStack {
                    Text(record.button)
                    Spacer()
                    Text("\(record.timestamp, formatter: dateFormatter)")
                    if let duration = record.duration {
                        Text("(\(String(format: "%.2f", duration))s)")
                    }
                }
            }
            .frame(maxHeight: 200)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
}
