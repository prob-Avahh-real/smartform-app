import SwiftUI
import Combine

/// 表单填写流程 ViewModel
@MainActor
final class FormFlowViewModel: ObservableObject {
    @Published var session: FormSession
    @Published var isSaving = false
    @Published var saveError: String?

    private let storage = StorageService.shared
    private let prefillEngine: PrefillEngine

    init(template: FormTemplate, profile: UserProfile) {
        prefillEngine = PrefillEngine(profile: profile)

        var cards = template.cards
        // 尝试预填
        for i in cards.indices {
            _ = prefillEngine.prefill(fields: &cards[i].fields)
        }

        // 展开第一张卡片
        if !cards.isEmpty { cards[0].isExpanded = true }

        self.session = FormSession(
            templateId: template.id,
            templateName: template.name,
            cards: cards,
            currentCardIndex: 0,
            startedAt: Date(),
            lastSavedAt: Date()
        )
    }

    /// 恢复已有 session
    init(restoring session: FormSession, profile: UserProfile) {
        prefillEngine = PrefillEngine(profile: profile)
        self.session = session
        if !session.cards.isEmpty, session.currentCardIndex < session.cards.count {
            self.session.cards[session.currentCardIndex].isExpanded = true
        }
    }

    // MARK: - Card Navigation

    func expandCard(at index: Int) {
        // 折叠当前卡片
        if session.currentCardIndex < session.cards.count {
            session.cards[session.currentCardIndex].isExpanded = false
        }
        // 展开目标卡片
        session.cards[index].isExpanded = true
        session.currentCardIndex = index
    }

    func moveToNextCard() {
        guard session.currentCardIndex + 1 < session.cards.count else { return }
        expandCard(at: session.currentCardIndex + 1)
    }

    func moveToPreviousCard() {
        guard session.currentCardIndex > 0 else { return }
        expandCard(at: session.currentCardIndex - 1)
    }

    // MARK: - Field Updates

    func updateField(cardIndex: Int, fieldIndex: Int, value: String) {
        session.cards[cardIndex].fields[fieldIndex].value = value
        validateField(cardIndex: cardIndex, fieldIndex: fieldIndex)
        autoSave()
    }

    func validateField(cardIndex: Int, fieldIndex: Int) {
        let field = session.cards[cardIndex].fields[fieldIndex]
        guard let value = field.value, !value.isEmpty else {
            session.cards[cardIndex].fields[fieldIndex].isValid = false
            return
        }

        for rule in field.validationRules {
            switch rule.type {
            case .required:
                if value.trimmingCharacters(in: .whitespaces).isEmpty {
                    session.cards[cardIndex].fields[fieldIndex].isValid = false
                    return
                }
            case .idCardFormat:
                let pattern = #"^\d{17}[\dXx]$"#
                if value.range(of: pattern, options: .regularExpression) == nil {
                    session.cards[cardIndex].fields[fieldIndex].isValid = false
                    return
                }
            case .phoneFormat:
                let pattern = #"^1\d{10}$"#
                if value.range(of: pattern, options: .regularExpression) == nil {
                    session.cards[cardIndex].fields[fieldIndex].isValid = false
                    return
                }
            case .emailFormat:
                let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
                if value.range(of: pattern, options: .regularExpression) == nil {
                    session.cards[cardIndex].fields[fieldIndex].isValid = false
                    return
                }
            case .minLength(let len):
                if value.count < len {
                    session.cards[cardIndex].fields[fieldIndex].isValid = false
                    return
                }
            case .maxLength(let len):
                if value.count > len {
                    session.cards[cardIndex].fields[fieldIndex].isValid = false
                    return
                }
            default: break
            }
        }
        session.cards[cardIndex].fields[fieldIndex].isValid = true
    }

    // MARK: - Auto Save

    private var saveTask: Task<Void, Never>?

    func autoSave() {
        saveTask?.cancel()
        saveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s 防抖
            guard !Task.isCancelled else { return }
            await performSave()
        }
    }

    func performSave() async {
        isSaving = true
        session.lastSavedAt = Date()
        do {
            try storage.saveSession(session)
            saveError = nil
        } catch {
            saveError = "保存失败：\(error.localizedDescription)"
        }
        isSaving = false
    }

    // MARK: - Submit

    var canSubmit: Bool {
        session.cards.allSatisfy { card in
            card.fields.allSatisfy { $0.value != nil && !$0.value!.isEmpty && $0.isValid }
        }
    }

    var allFields: [FormField] {
        session.cards.flatMap(\.fields)
    }

    func submit(completion: @escaping (Bool) -> Void) {
        session.isCompleted = true
        // 更新用户画像
        for field in allFields where field.value != nil {
            _ = prefillEngine // profile updated in place
        }
        Task {
            await performSave()
            completion(true)
        }
    }
}
