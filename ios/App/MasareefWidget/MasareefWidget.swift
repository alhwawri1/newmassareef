import WidgetKit
import SwiftUI

struct ChecklistPreviewItem: Codable, Identifiable {
    let id: String
    let name: String
    let qty: String
    let price: Double
}

struct MasareefWidgetSnapshot: Codable {
    let updatedAt: String
    let lang: String
    let privacy: Bool
    let currency: String
    let decimals: Int
    let selectedMonth: String
    let monthLabel: String
    let totalSpent: Double
    let monthlyBudget: Double
    let remaining: Double
    let percentUsed: Int
    let expenseCount: Int
    let activeListName: String
    let uncheckedInActiveList: Int
    let totalUncheckedAllLists: Int
    let estChecklistTotal: Double
    let topChecklistItems: [ChecklistPreviewItem]
    let recurringCount: Int
    let nextRecurringTitle: String
    let nextRecurringAmount: Double

    static let placeholder = MasareefWidgetSnapshot(
        updatedAt: "",
        lang: "ar",
        privacy: false,
        currency: "OMR",
        decimals: 3,
        selectedMonth: "2026-11",
        monthLabel: "نوفمبر 2026",
        totalSpent: 145.500,
        monthlyBudget: 500.000,
        remaining: 354.500,
        percentUsed: 29,
        expenseCount: 12,
        activeListName: "السوبرماركت",
        uncheckedInActiveList: 3,
        totalUncheckedAllLists: 3,
        estChecklistTotal: 4.800,
        topChecklistItems: [
            ChecklistPreviewItem(id: "1", name: "حليب طازج", qty: "2", price: 1.200),
            ChecklistPreviewItem(id: "2", name: "خبز أسمر", qty: "1", price: 0.400),
            ChecklistPreviewItem(id: "3", name: "قهوة", qty: "1", price: 3.200)
        ],
        recurringCount: 2,
        nextRecurringTitle: "اشتراك الإنترنت",
        nextRecurringAmount: 28.000
    )

    func formatAmount(_ val: Double) -> String {
        if privacy { return "••••" }
        let clampedDecimals = max(0, min(4, decimals))
        return String(format: "%.*f", clampedDecimals, val)
    }
}

struct MasareefEntry: TimelineEntry {
    let date: Date
    let snapshot: MasareefWidgetSnapshot
}

struct MasareefTimelineProvider: TimelineProvider {
    private let appGroupSuite = "group.com.alhawari.masareef"
    private let snapshotKey = "masareef_widget_snapshot_v1"

    func placeholder(in context: Context) -> MasareefEntry {
        MasareefEntry(date: Date(), snapshot: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (MasareefEntry) -> Void) {
        completion(MasareefEntry(date: Date(), snapshot: loadSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MasareefEntry>) -> Void) {
        let entry = MasareefEntry(date: Date(), snapshot: loadSnapshot())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date().addingTimeInterval(1800)
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadSnapshot() -> MasareefWidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: appGroupSuite),
              let raw = defaults.string(forKey: snapshotKey),
              let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode(MasareefWidgetSnapshot.self, from: data) else {
            return .placeholder
        }
        return decoded
    }
}

// MARK: - 1. Budget & Monthly Pulse Widget
struct BudgetPulseWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: MasareefEntry

    private var isAr: Bool { entry.snapshot.lang == "ar" }
    private var pctFraction: Double {
        min(1.0, max(0.0, Double(entry.snapshot.percentUsed) / 100.0))
    }
    private var statusColor: Color {
        if !entry.snapshot.privacy && entry.snapshot.remaining < 0 { return .red }
        if !entry.snapshot.privacy && entry.snapshot.percentUsed >= 80 { return .orange }
        return Color(red: 0.06, green: 0.73, blue: 0.51)
    }

    var body: some View {
        let snap = entry.snapshot
        VStack(alignment: isAr ? .trailing : .leading, spacing: 8) {
            HStack {
                Text(isAr ? "مصاريف الشهر" : "Monthly Spent")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Text(snap.privacy ? "••%" : "\(snap.percentUsed)%")
                    .font(.caption.bold().monospacedDigit())
                    .foregroundStyle(statusColor)
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(snap.formatAmount(snap.totalSpent))
                    .font(.title2.bold().monospacedDigit())
                    .foregroundStyle(.primary)
                Text(snap.currency)
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.06, green: 0.73, blue: 0.51))
            }

            ProgressView(value: snap.privacy ? 0.35 : pctFraction)
                .tint(statusColor)

            HStack {
                if snap.remaining >= 0 || snap.privacy {
                    Text(isAr ? "المتبقي: \(snap.formatAmount(snap.remaining)) \(snap.currency)"
                              : "Left: \(snap.formatAmount(snap.remaining)) \(snap.currency)")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                } else {
                    Text(isAr ? "تجاوز: \(snap.formatAmount(abs(snap.remaining))) \(snap.currency)"
                              : "Over: \(snap.formatAmount(abs(snap.remaining))) \(snap.currency)")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(.red)
                        .lineLimit(1)
                }
                Spacer()
                if family == .systemMedium {
                    Link(destination: URL(string: "masareef://add-expense")!) {
                        Label(isAr ? "إضافة" : "Add", systemImage: "plus.circle.fill")
                            .font(.caption.bold())
                            .foregroundStyle(Color(red: 0.02, green: 0.71, blue: 0.83))
                    }
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "masareef://expenses"))
    }
}

struct BudgetPulseWidget: Widget {
    let kind: String = "MasareefBudgetWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MasareefTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                BudgetPulseWidgetView(entry: entry)
                    .containerBackground(Color(red: 0.04, green: 0.05, blue: 0.09), for: .widget)
            } else {
                BudgetPulseWidgetView(entry: entry)
                    .background(Color(red: 0.04, green: 0.05, blue: 0.09))
            }
        }
        .configurationDisplayName("Masareef Budget")
        .description("Track monthly spending, remaining budget, and quick add.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - 2. Shopping Checklist Widget
struct ShoppingChecklistWidgetView: View {
    let entry: MasareefEntry
    private var isAr: Bool { entry.snapshot.lang == "ar" }

    var body: some View {
        let snap = entry.snapshot
        VStack(alignment: isAr ? .trailing : .leading, spacing: 6) {
            HStack {
                Label(snap.activeListName.isEmpty ? (isAr ? "المشتريات" : "Checklist") : snap.activeListName,
                      systemImage: "cart.fill")
                    .font(.caption.bold())
                    .foregroundStyle(Color(red: 0.06, green: 0.73, blue: 0.51))
                Spacer()
                Text("\(snap.uncheckedInActiveList)")
                    .font(.caption.bold().monospacedDigit())
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.2))
                    .clipShape(Capsule())
            }

            if snap.topChecklistItems.isEmpty {
                Spacer()
                Text(isAr ? "لا توجد عناصر متبقية" : "All items checked off")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ForEach(snap.topChecklistItems.prefix(4)) { item in
                    HStack {
                        Image(systemName: "circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Text(item.name)
                            .font(.caption)
                            .lineLimit(1)
                        Spacer()
                        if !item.qty.isEmpty {
                            Text("×\(item.qty)")
                                .font(.caption2.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .widgetURL(URL(string: "masareef://checklist"))
    }
}

struct ShoppingChecklistWidget: Widget {
    let kind: String = "MasareefChecklistWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MasareefTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                ShoppingChecklistWidgetView(entry: entry)
                    .containerBackground(Color(red: 0.04, green: 0.05, blue: 0.09), for: .widget)
            } else {
                ShoppingChecklistWidgetView(entry: entry)
                    .background(Color(red: 0.04, green: 0.05, blue: 0.09))
            }
        }
        .configurationDisplayName("Masareef Checklist")
        .description("Quick preview of unchecked items in your active shopping list.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - 3. Lock Screen Accessory Widgets
struct LockScreenBudgetWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: MasareefEntry
    private var isAr: Bool { entry.snapshot.lang == "ar" }

    var body: some View {
        let snap = entry.snapshot
        switch family {
        case .accessoryCircular:
            Gauge(value: snap.privacy ? 0.3 : min(1.0, max(0.0, Double(snap.percentUsed) / 100.0))) {
                Text(snap.currency)
                    .font(.system(size: 8, weight: .bold))
            } currentValueLabel: {
                Text(snap.privacy ? "•" : "\(snap.percentUsed)%")
                    .font(.caption2.bold().monospacedDigit())
            }
            .gaugeStyle(.accessoryCircular)
            .widgetURL(URL(string: "masareef://expenses"))

        default:
            VStack(alignment: isAr ? .trailing : .leading, spacing: 2) {
                Text(isAr ? "المصروف الشهري" : "Monthly Spent")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text("\(snap.formatAmount(snap.totalSpent)) \(snap.currency)")
                    .font(.headline.bold().monospacedDigit())
                Text(isAr ? "المتبقي: \(snap.formatAmount(snap.remaining))" : "Left: \(snap.formatAmount(snap.remaining))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .widgetURL(URL(string: "masareef://expenses"))
        }
    }
}

struct LockScreenBudgetWidget: Widget {
    let kind: String = "MasareefLockScreenWidget"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MasareefTimelineProvider()) { entry in
            if #available(iOS 17.0, *) {
                LockScreenBudgetWidgetView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                LockScreenBudgetWidgetView(entry: entry)
            }
        }
        .configurationDisplayName("Masareef Lock Screen")
        .description("Lock screen budget & spending summary.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular])
    }
}

@main
struct MasareefWidgetBundle: WidgetBundle {
    var body: some Widget {
        BudgetPulseWidget()
        ShoppingChecklistWidget()
        LockScreenBudgetWidget()
    }
}
