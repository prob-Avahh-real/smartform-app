import SwiftUI

@main
struct SmartFormApp: App {
    @StateObject private var homeVM = HomeViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(homeVM)
        }
    }
}

// MARK: - Color Extensions

extension Color {
    static let sfPrimary   = Color(red: 74/255, green: 144/255, blue: 217/255)  // 天青蓝
    static let sfAccent    = Color(red: 52/255, green: 199/255, blue: 89/255)   // 薄荷绿
    static let sfWarning   = Color(red: 255/255, green: 149/255, blue: 0/255)   // 暖琥珀
    static let sfError     = Color(red: 255/255, green: 107/255, blue: 107/255) // 柔和珊瑚
    static let sfInfo      = Color(red: 90/255, green: 200/255, blue: 250/255)  // 天空蓝
    static let sfBg        = Color(red: 245/255, green: 245/255, blue: 247/255) // 暖灰白
}

struct ContentView: View {
    @EnvironmentObject var homeVM: HomeViewModel

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem { Label("首页", systemImage: "house.fill") }

            NavigationStack {
                HistoryView()
            }
            .tabItem { Label("历史", systemImage: "clock.fill") }

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label("我的", systemImage: "person.fill") }
        }
        .tint(.sfPrimary)
    }
}

// MARK: - History View

struct HistoryView: View {
    @State private var sessions: [FormSession] = []

    var body: some View {
        List {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "暂无历史记录",
                    systemImage: "tray",
                    description: Text("填过的表单会出现在这里")
                )
            } else {
                ForEach(sessions) { session in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.templateName).font(.headline)
                            Text("进度 \(Int(session.progress * 100))% · \(session.completedCards)/\(session.totalCards) 卡片")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if session.isCompleted {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.sfAccent)
                        }
                    }
                }
            }
        }
        .navigationTitle("历史记录")
        .onAppear { sessions = StorageService.shared.loadAllSessions() }
    }
}

// MARK: - Profile View

struct ProfileView: View {
    @State private var profile: UserProfile?
    @State private var showSetup = false

    var body: some View {
        List {
            if let p = profile {
                Section("个人信息") {
                    row("姓名", p.name)
                    row("身份证", p.idCard?.maskedIdCard)
                    row("手机", p.phone)
                    row("邮箱", p.email)
                }
                Section {
                    Button("重新初始化画像") { showSetup = true }
                }
            } else {
                ContentUnavailableView(
                    "未设置安全画像",
                    systemImage: "lock.shield",
                    description: Text("设置画像后可自动预填表单信息")
                )
                Section {
                    Button("创建安全画像") { showSetup = true }
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("我的")
        .onAppear { profile = StorageService.shared.loadProfile() }
        .sheet(isPresented: $showSetup) {
            ProfileSetupView { newProfile in
                profile = newProfile
                try? StorageService.shared.saveProfile(newProfile)
            }
        }
    }

    private func row(_ label: String, _ value: String?) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value ?? "未设置").foregroundStyle(value == nil ? .tertiary : .primary)
        }
    }
}

private extension String {
    var maskedIdCard: String {
        guard count == 18 else { return self }
        let start = index(startIndex, offsetBy: 3)
        let end = index(startIndex, offsetBy: 14)
        return replacingCharacters(in: start..<end, with: "**** **** ****")
    }
}

extension Character {
    var isCJK: Bool {
        let scalars = unicodeScalars
        guard let scalar = scalars.first else { return false }
        return (0x4E00...0x9FFF).contains(scalar.value)
            || (0x3400...0x4DBF).contains(scalar.value)
    }
}
