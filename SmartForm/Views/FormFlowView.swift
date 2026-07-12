import SwiftUI

/// 卡片式填表流程主视图
struct FormFlowView: View {
    @StateObject private var vm: FormFlowViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPreview = false

    // 新建表单
    init(template: FormTemplate) {
        let profile = StorageService.shared.loadProfile() ?? UserProfile()
        _vm = StateObject(wrappedValue: FormFlowViewModel(template: template, profile: profile))
    }

    // 继续填写
    init(restoring session: FormSession) {
        let profile = StorageService.shared.loadProfile() ?? UserProfile()
        _vm = StateObject(wrappedValue: FormFlowViewModel(restoring: session, profile: profile))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        // 进度条
                        ProgressHeader(
                            title: vm.session.templateName,
                            progress: vm.session.progress,
                            completedCards: vm.session.completedCards,
                            totalCards: vm.session.totalCards
                        )
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)

                        // 卡片列表
                        LazyVStack(spacing: 12) {
                            ForEach(Array(vm.session.cards.enumerated()), id: \.element.id) { index, card in
                                CardView(
                                    card: card,
                                    cardIndex: index,
                                    isCurrent: index == vm.session.currentCardIndex,
                                    onExpand: { vm.expandCard(at: index) },
                                    onFieldUpdate: { fieldIndex, value in
                                        vm.updateField(cardIndex: index, fieldIndex: fieldIndex, value: value)
                                    }
                                )
                                .id(card.id)
                            }
                        }
                        .padding(.horizontal, 24)

                        // 底部间距
                        Color.clear.frame(height: 100)
                    }
                }
                .background(Color.sfBg)
                .onChange(of: vm.session.currentCardIndex) { _, newIndex in
                    withAnimation {
                        proxy.scrollTo(vm.session.cards[newIndex].id, anchor: .top)
                    }
                }
            }

            // 底部提交栏
            bottomBar
        }
        .navigationTitle(vm.session.templateName)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if vm.isSaving {
                    ProgressView()
                } else {
                    Image(systemName: "checkmark.icloud").foregroundStyle(.sfAccent)
                }
            }
        }
        .sheet(isPresented: $showPreview) {
            FormPreviewView(session: vm.session) {
                vm.submit { _ in dismiss() }
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 16) {
                // 上一步
                Button {
                    vm.moveToPreviousCard()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("上一步")
                    }
                    .font(.subheadline)
                }
                .disabled(vm.session.currentCardIndex == 0)
                .opacity(vm.session.currentCardIndex == 0 ? 0.3 : 1)

                Spacer()

                // 自动保存指示
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.icloud").font(.caption2)
                    Text("已自动保存").font(.caption2)
                }
                .foregroundStyle(.sfAccent)
                .opacity(vm.isSaving ? 0 : 1)

                if vm.isSaving {
                    ProgressView().scaleEffect(0.8)
                }

                Spacer()

                // 下一步 / 提交
                if vm.session.currentCardIndex == vm.session.totalCards - 1 {
                    Button {
                        showPreview = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("预览提交")
                            Image(systemName: "checkmark")
                        }
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(vm.canSubmit ? Color.sfAccent : Color.gray.opacity(0.3))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!vm.canSubmit)
                } else {
                    Button {
                        vm.moveToNextCard()
                    } label: {
                        HStack(spacing: 4) {
                            Text("下一步")
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline).fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20).padding(.vertical, 10)
                        .background(
                            vm.session.cards[vm.session.currentCardIndex].isCompleted
                                ? Color.sfPrimary : Color.gray.opacity(0.3)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(!vm.session.cards[vm.session.currentCardIndex].isCompleted)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }
}

// MARK: - Progress Header

struct ProgressHeader: View {
    let title: String
    let progress: Double
    let completedCards: Int
    let totalCards: Int

    var body: some View {
        VStack(spacing: 12) {
            // 进度条
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.sfPrimary, .sfAccent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * max(progress, 0.02), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(Int(progress * 100))%").font(.caption).foregroundStyle(.sfPrimary).fontWeight(.medium)
                Spacer()
                Text("\(completedCards)/\(totalCards) 卡片").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
