
import SwiftUI
import Combine
import UserNotifications
// خدمة الإشعارات (نفس الكود بدون تغيير)
struct NotificationManager {

    static let shared = NotificationManager()

    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
                if let error = error { print("Notification permission error: \(error)") }
            }
    }

    func schedule(for plant: Plant) {
        let content = UNMutableNotificationContent()
        content.title = "Planto"
        content.body = "Hey! let's water your \(plant.name)"
        content.sound = .default

        // للتجربة: let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(identifier: plant.id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancel(for plant: Plant) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [plant.id])
    }
}
//استخدمت الكلاس لان عدة شاشات تشارك نفس النسخه
//ObservableObject يخلي الشاشات تراقب الكلاس
// MARK: - ViewModel: يدير بيانات النباتات وكل العمليات عليها

final class PlantsViewModel: ObservableObject {

    // البيانات (@Published: أي تغيير يحدّث الشاشات تلقائياً)
    @Published var plants: [Plant] = []
    @Published var completedPlants: Set<String> = []
    @Published var selectedPlant: Plant? = nil
    @Published var showPopup = false
    @Published var showNoReminders = false
    @Published var showTodayReminders = false

    // قيم محسوبة
    //عدد النباتات المعلّمة. استخدمت intersection (المشترك) عشان لو انحذفت نبتة وهي معلّمة، ما تنحسب.
    var completedCount: Int {
        completedPlants.intersection(plants.map(\.id)).count
    }
    var progress: Double {
        plants.isEmpty ? 0 : Double(completedCount) / Double(plants.count)
    }
    var allCompleted: Bool {
        !plants.isEmpty && completedCount == plants.count
    }

    // العمليات
    func add(_ plant: Plant) {                      // إضافة نبتة
        plants.append(plant)
        NotificationManager.shared.schedule(for: plant)
        showPopup = false
        showNoReminders = false
        showTodayReminders = true
    }

    func cancelAdd() {                              // إلغاء الإضافة
        showPopup = false
        if plants.isEmpty { showNoReminders = true }
    }

    func update(_ plant: Plant) {                   // تعديل نبتة
        guard let index = plants.firstIndex(where: { $0.id == plant.id }) else { return }
        plants[index] = plant
        NotificationManager.shared.schedule(for: plant)
    }

    func delete(_ plant: Plant) {                   // حذف نبتة
        NotificationManager.shared.cancel(for: plant)
        plants.removeAll { $0.id == plant.id }
        completedPlants.remove(plant.id)
    }

    func toggle(_ plant: Plant) {                   // تعليم صح / إلغاء
        if completedPlants.contains(plant.id) {
            completedPlants.remove(plant.id)
        } else {
            completedPlants.insert(plant.id)
        }
    }

    func isCompleted(_ plant: Plant) -> Bool {
        completedPlants.contains(plant.id)
    }
}
struct ReminderSheet: View {

    let onCancel: () -> Void
    let onSave: (Plant) -> Void

    @State private var plantName = ""
    @State private var room = "Bedroom"
    @State private var light = "Full sun"
    @State private var wateringDays = "Every day"
    @State private var water = "20–50 ml"

    var body: some View {

        VStack(spacing: 0) {

            ReminderSheetHeader(

                dismiss: {
                    onCancel()
                },

                save: {

                    let newPlant = Plant(
                        id: UUID().uuidString,
                        name: plantName.trimmingCharacters(
                            in: .whitespacesAndNewlines
                        ),
                        room: room,
                        light: light,
                        wateringDays: wateringDays,
                        water: water
                    )

                    onSave(newPlant)
                },

                isSaveDisabled: plantName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .isEmpty
            )

            ScrollView {

                VStack(spacing: 24) {

                    PlantNameField(
                        plantName: $plantName
                    )

                    ReminderOptionsCard(
                        room: $room,
                        light: $light
                    )

                    WateringOptionsCard(
                        wateringDays: $wateringDays,
                        water: $water
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 32)
            }
        }
    }
}



struct ReminderSheetHeader: View {

    let dismiss: () -> Void
    let save: () -> Void
    let isSaveDisabled: Bool

    var body: some View {

        HStack {

            Button(action: dismiss) {

                Image(systemName: "xmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(.white.opacity(0.16))
                    .clipShape(Circle())
            }
            .accessibilityLabel("Close reminder")

            Spacer()

            Text("Add Plant")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Spacer()

            Button(action: save) {

                Image(systemName: "checkmark")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        Color(red: 0.25, green: 0.82, blue: 0.62)
                    )
                    .clipShape(Circle())
            }
            .disabled(isSaveDisabled)
            .opacity(isSaveDisabled ? 0.4 : 1)
            .accessibilityLabel("Save plant")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }
}


struct PlantNameField: View {
    @Binding var plantName: String

    var body: some View {
        HStack(spacing: 12) {
            Text("Plant Name")
                .foregroundStyle(.white)

            TextField("Plant name", text: $plantName)
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(18)
        .background(.white.opacity(0.12))
        .clipShape(Capsule())
    }
}

struct ReminderOptionsCard: View {
    @Binding var room: String
    @Binding var light: String

    var body: some View {
        VStack(spacing: 0) {
            ReminderMenuRow(
                icon: "location.north.fill",
                title: "Room",
                value: $room,
                options: ["Bedroom", "Living Room", "Kitchen", "Balcony", "Bathroom"]
            )

            Divider()
                .overlay(.white.opacity(0.2))

            ReminderMenuRow(
                icon: "sun.max.fill",
                title: "Light",
                value: $light,
                options: ["Full sun", "Partial sun", "Low light"]
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

struct WateringOptionsCard: View {
    @Binding var wateringDays: String
    @Binding var water: String

    var body: some View {
        VStack(spacing: 0) {
            ReminderMenuRow(
                icon: "calendar",
                title: "Watering Days",
                value: $wateringDays,
                options: ["Every day", "Every 2 days", "Every 3 days", "Once a week", "Every 10 days", "Every 2 weeks"]
            )

            Divider()
                .overlay(.white.opacity(0.2))

            ReminderMenuRow(
                icon: "drop.fill",
                title: "Water",
                value: $water,
                options: ["20–50 ml", "50–100 ml", "100–200 ml", "200–300 ml"]
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 28))
    }
}

struct ReminderMenuRow: View {
    let icon: String
    let title: String
    @Binding var value: String
    let options: [String]

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.white)
                .frame(width: 20)

            Text(title)
                .foregroundStyle(.white)

            Spacer()

            Menu {
                ForEach(options, id: \.self) { option in
                    Button(option) {
                        value = option
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(value)
                        .foregroundStyle(.white)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 13)
    }
}


    #Preview {
        ReminderSheet(
            onCancel: {},
            onSave: { newPlant in }
        )
    }

#Preview {
    ContentView()
}
