import SwiftUI

struct ContentView: View {

    @StateObject private var vm = PlantsViewModel()     // ننشئ الـ ViewModel مرة وحدة

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if vm.showTodayReminders {
                TodayReminders(vm: vm)
                    .sheet(item: $vm.selectedPlant) { plant in
                        PlantFormSheet(
                            plant: plant,
                            onSave: vm.update,
                            onDelete: { vm.delete(plant) }
                        )
                    }
            } else if vm.showNoReminders {
                NoRemindersView()
            } else {
                WelcomeView { vm.showPopup = true }
            }
        }
        .onAppear { NotificationManager.shared.requestPermission() }
        .sheet(isPresented: $vm.showPopup) {
            ReminderSheet(onCancel: vm.cancelAdd, onSave: vm.add)
                .presentationDetents([.fraction(0.9)])
                .presentationCornerRadius(40)
                .presentationBackground(Color(red: 0.20, green: 0.21, blue: 0.21))
                .presentationDragIndicator(.hidden)
        }
    }
}
struct NoRemindersView: View {
    var body: some View {
        VStack(spacing: 0) {
            PlantsHeader()
            Spacer()
            Text("No reminders set yet…")
                .font(.subheadline)
                .foregroundStyle(.white)
            Spacer()
        }
    }
}
struct PlantFormSheet: View {

    @Environment(\.dismiss) private var dismiss

    let plant: Plant?
    let onSave: (Plant) -> Void
    let onDelete: () -> Void

    @State private var plantName: String
    @State private var room: String
    @State private var light: String
    @State private var wateringDays: String
    @State private var water: String

    init(plant: Plant?, onSave: @escaping (Plant) -> Void, onDelete: @escaping () -> Void) {
        self.plant = plant
        self.onSave = onSave
        self.onDelete = onDelete
        _plantName = State(initialValue: plant?.name ?? "")
        _room = State(initialValue: plant?.room ?? "Bedroom")
        _light = State(initialValue: plant?.light ?? "Full sun")
        _wateringDays = State(initialValue: plant?.wateringDays ?? "Every day")
        _water = State(initialValue: plant?.water ?? "20-50 ml")
    }

    var body: some View {
        VStack(spacing: 25) {

            // الهيدر
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(.white.opacity(0.12))
                        .clipShape(Circle())
                }

                Spacer()

                Text(plant == nil ? "Add Plant" : "Edit Plant")
                    .foregroundStyle(.white)
                    .font(.headline)

                Spacer()

                Button {
                    guard !plantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    onSave(Plant(
                        id: plant?.id ?? UUID().uuidString,
                        name: plantName,
                        room: room,
                        light: light,
                        wateringDays: wateringDays,
                        water: water
                    ))
                    dismiss()
                } label: {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.white)
                        .frame(width: 38, height: 38)
                        .background(Color(red: 0.25, green: 0.82, blue: 0.62))
                        .clipShape(Circle())
                }
            }
            .padding(.top, 20)

            // الحقول
            TextField("Plant Name", text: $plantName)
                .foregroundStyle(.white)
                .padding(16)
                .background(.white.opacity(0.09))
                .clipShape(Capsule())

            VStack(spacing: 0) {
                TextField("Room", text: $room)
                    .foregroundStyle(.white)
                    .padding(14)
                Divider().background(.white.opacity(0.12))
                TextField("Light", text: $light)
                    .foregroundStyle(.white)
                    .padding(14)
            }
            .background(.white.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 22))

            VStack(spacing: 0) {
                TextField("Watering Days", text: $wateringDays)
                    .foregroundStyle(.white)
                    .padding(14)
                Divider().background(.white.opacity(0.12))
                TextField("Water", text: $water)
                    .foregroundStyle(.white)
                    .padding(14)
            }
            .background(.white.opacity(0.09))
            .clipShape(RoundedRectangle(cornerRadius: 22))

            Spacer()

            // زر الحذف (في التعديل فقط)
            if plant != nil {
                Button(role: .destructive) {
                    onDelete()
                    dismiss()
                } label: {
                    Text("Delete Reminder")
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(.white.opacity(0.09))
                        .clipShape(Capsule())
                }
            }

            Spacer().frame(height: 10)
        }
        .padding(.horizontal, 20)
        .background(Color(red: 0.12, green: 0.12, blue: 0.13).ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}
struct PlantsHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("My Plants 🌱")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
            }
            Rectangle()
                .fill(.white.opacity(0.2))
                .frame(height: 1)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
}
struct TodayReminders: View {

    @ObservedObject var vm: PlantsViewModel         // الـ ViewModel اللي جاي من ContentView

    private let green = Color(red: 0.25, green: 0.82, blue: 0.62)

    var body: some View {
        VStack(spacing: 0) {

            // العنوان
            HStack {
                Text("My Plants 🌱")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(height: 1)
                .padding(.top, 18)

            // نص التقدم
            Text("\(vm.completedCount) of your plants feel loved today✨")
                .font(.subheadline)
                .foregroundStyle(.white)
                .padding(.top, 28)

            // شريط التقدم
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.18))
                    Capsule()
                        .fill(green)
                        .frame(width: geometry.size.width * vm.progress)
                        .animation(.easeInOut(duration: 0.3), value: vm.completedCount)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 20)
            .padding(.top, 12)

            // All Done أو القائمة
            if vm.allCompleted {
                VStack(spacing: 0) {
                    Spacer()
                    Image(.plantsimage)
                        .accessibilityHidden(true)
                    Text("All Done! 🎉")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.top, 24)
                    Text("All Reminders Completed")
                        .foregroundStyle(.white.opacity(0.5))
                        .padding(.top, 8)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
            } else {
                List {
                    ForEach(vm.plants) { plant in
                        HStack(spacing: 12) {

                            // زر الصح
                            Button { vm.toggle(plant) } label: {
                                Image(systemName: vm.isCompleted(plant) ? "checkmark.circle.fill" : "circle")
                                    .font(.title3)
                                    .foregroundStyle(vm.isCompleted(plant) ? green : .gray)
                            }
                            .buttonStyle(.plain)

                            // معلومات النبتة (الضغط = تعديل)
                            Button { vm.selectedPlant = plant } label: {
                                VStack(alignment: .leading, spacing: 7) {
                                    HStack(spacing: 5) {
                                        Image(systemName: "location.north").font(.caption2)
                                        Text("in \(plant.room)").font(.caption)
                                    }
                                    .foregroundStyle(.gray)

                                    Text(plant.name)
                                        .font(.title3)
                                        .foregroundStyle(vm.isCompleted(plant) ? .gray : .white)

                                    HStack(spacing: 8) {
                                        Text("☀️ \(plant.light)")
                                        Text("💧 \(plant.water)")
                                    }
                                    .font(.caption2)
                                    .foregroundStyle(.gray)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 12)
                        .listRowBackground(Color.black)
                        .listRowSeparatorTint(.white.opacity(0.12))
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { vm.delete(plant) } label: {
                                Image(systemName: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            // زر الإضافة
            HStack {
                Spacer()
                Button { vm.showPopup = true } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 52)
                        .background(green.opacity(0.65))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 25)
            .padding(.bottom, 24)
        }
        .background(Color.black.ignoresSafeArea())
    }
}
struct WelcomeView: View {
    let setReminder: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            PlantsHeader()
            Spacer()

            Image(.GST_DACAR_121_02_1)
                .accessibilityHidden(true)

            Text("Start your plant journey")
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .padding(.top, 24)

            Text("Keep all your plants in one place, and we’ll help you take care of them.")
                .foregroundStyle(.white.opacity(0.75))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .padding(.horizontal, 32)

            Spacer()

            Button(action: setReminder) {
                Text("Set Plant Reminder")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color(red: 0.25, green: 0.82, blue: 0.62))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }
}

#Preview {
    ContentView()
}
