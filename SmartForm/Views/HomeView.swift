import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var templates: [FormTemplate] = []
    @Published var recentSessions: [FormSession] = []
    @Published var searchText = ""

    var filteredTemplates: [FormTemplate] {
        if searchText.isEmpty { return templates }
        return templates.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }

    init() {
        templates = TemplateService.shared.loadBuiltInTemplates()
        recentSessions = StorageService.shared.loadAllSessions().filter { !$0.isCompleted }
    }

    func refresh() {
        recentSessions = StorageService.shared.loadAllSessions().filter { !$0.isCompleted }
    }
}

// MARK: - Home View

struct HomeView: View {
    @EnvironmentObject var homeVM: HomeViewModel
    @State private var selectedTemplate: FormTemplate?
    @State private var selectedSession: FormSession?
    @State private var showScanner = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection

                // Search Bar
                searchBar

                // Quick Actions
                quickActions

                // Continue Sessions
                if !homeVM.recentSessions.isEmpty {
                    continueSection
                }

                // Template Gallery
                templateGallery
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
        }
        .background(Color.sfBg)
        .navigationTitle("SmartForm")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { homeVM.refresh() }
        .navigationDestination(item: $selectedTemplate) { template in
            FormFlowView(template: template)
        }
        .navigationDestination(item: $selectedSession) { session in
            FormFlowView(restoring: session)
        }
        .sheet(isPresented: $showScanner) {
            Text("扫描表格功能即将上线")
                .font(.title2)
                .presentationDetents([.medium])
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("表格应该适应你")
                        .font(.title2).fontWeight(.bold)
                    Text("而不是你适应表格")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Search

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("描述你要填什么表...或说出指令", text: $homeVM.searchText)
                .font(.body)
            Button(action: {}) {
                Image(systemName: "mic.fill").foregroundStyle(.sfPrimary)
            }
        }
        .padding(14)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.04), radius: 8, y: 2)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "doc.viewfinder.fill",
                label: "扫描表格",
                color: .sfPrimary,
                action: { showScanner = true }
            )
            QuickActionButton(
                icon: "square.grid.2x2.fill",
                label: "模板市场",
                color: .sfAccent,
                action: {}
            )
            QuickActionButton(
                icon: "building.columns.fill",
                label: "政务办事",
                color: .sfWarning,
                action: { homeVM.searchText = "政务" }
            )
        }
    }

    private var continueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("继续填写").font(.headline)

            ForEach(homeVM.recentSessions.prefix(3)) { session in
                Button {
                    selectedSession = session
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(session.templateName).font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Text("上次: \(session.lastSavedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        ProgressView(value: session.progress)
                            .frame(width: 80)
                        Text("\(Int(session.progress * 100))%")
                            .font(.caption).foregroundStyle(.sfPrimary)
                    }
                    .padding(14)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
    }

    // MARK: - Template Gallery

    private var templateGallery: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("表单模板").font(.headline)

            LazyVGrid(columns: [.init(.flexible()), .init(.flexible())], spacing: 12) {
                ForEach(homeVM.filteredTemplates) { template in
                    Button {
                        selectedTemplate = template
                    } label: {
                        TemplateCard(template: template)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct QuickActionButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Text(label).font(.caption2).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct TemplateCard: View {
    let template: FormTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: template.iconName)
                .font(.title2)
                .foregroundStyle(.sfPrimary)
                .frame(width: 36, height: 36)
                .background(Color.sfPrimary.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(template.name)
                .font(.subheadline).fontWeight(.medium)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Text("约 \(template.estimatedMinutes) 分钟 · \(template.cards.count) 步")
                .font(.caption2).foregroundStyle(.secondary)

            Text(template.category.rawValue)
                .font(.caption2)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(categoryColor.opacity(0.12))
                .foregroundStyle(categoryColor)
                .clipShape(Capsule())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.03), radius: 6, y: 1)
    }

    private var categoryColor: Color {
        switch template.category {
        case .government: .sfWarning
        case .business:   .sfPrimary
        case .finance:    .sfAccent
        case .education:  .sfInfo
        case .healthcare: .sfError
        case .custom:     .secondary
        }
    }
}
