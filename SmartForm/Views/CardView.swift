import SwiftUI

/// 单张表单卡片 — 折叠/展开 + 字段编辑
struct CardView: View {
    let card: FormCard
    let cardIndex: Int
    let isCurrent: Bool
    let onExpand: () -> Void
    let onFieldUpdate: (Int, String) -> Void

    @State private var focusedField: Int?

    var body: some View {
        VStack(spacing: 0) {
            if card.isExpanded {
                expandedCard
            } else {
                collapsedCard
            }
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(isCurrent ? 0.06 : 0.03), radius: isCurrent ? 10 : 6, y: isCurrent ? 3 : 1)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrent ? Color.sfPrimary.opacity(0.3) : .clear, lineWidth: 1.5)
        )
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: card.isExpanded)
    }

    // MARK: - Collapsed

    private var collapsedCard: some View {
        Button(action: onExpand) {
            HStack(spacing: 12) {
                // 编号
                ZStack {
                    Circle()
                        .fill(card.isCompleted ? Color.sfAccent : Color.sfPrimary.opacity(0.12))
                        .frame(width: 32, height: 32)
                    if card.isCompleted {
                        Image(systemName: "checkmark").font(.caption2).fontWeight(.bold)
                            .foregroundStyle(.white)
                    } else {
                        Text("\(cardIndex + 1)")
                            .font(.caption).fontWeight(.bold)
                            .foregroundStyle(.sfPrimary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title).font(.subheadline).fontWeight(.medium)
                        .foregroundStyle(.primary)
                    if card.isCompleted {
                        // 已完成摘要
                        Text(fieldSummary).font(.caption).foregroundStyle(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("\(card.fields.count) 个字段待填写")
                            .font(.caption).foregroundStyle(.sfWarning)
                    }
                }
                Spacer()
                Image(systemName: "chevron.down").font(.caption).foregroundStyle(.secondary)
            }
            .padding(14)
        }
        .buttonStyle(.plain)
    }

    private var fieldSummary: String {
        card.fields.prefix(3).compactMap { $0.value }.joined(separator: " · ")
    }

    // MARK: - Expanded

    private var expandedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack(spacing: 10) {
                Image(systemName: card.iconName)
                    .font(.title3)
                    .foregroundStyle(.sfPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.sfPrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(card.title).font(.headline)
                    if let subtitle = card.subtitle {
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(cardIndex + 1)/\(cardIndex + 1)").font(.caption).foregroundStyle(.secondary)
                    .padding(.horizontal, 8).padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 20).padding(.top, 20)

            Divider().padding(.vertical, 12).padding(.horizontal, 20)

            // Fields
            ForEach(Array(card.fields.enumerated()), id: \.element.id) { fieldIndex, field in
                FieldRowView(
                    field: field,
                    fieldIndex: fieldIndex,
                    isFocused: focusedField == fieldIndex,
                    onUpdate: { value in
                        onFieldUpdate(fieldIndex, value)
                    },
                    onFocus: { focused in
                        focusedField = focused ? fieldIndex : nil
                    }
                )
            }

            // Footer — 完成卡片
            HStack {
                Spacer()
                Button {
                    // Swipe down to collapse
                    withAnimation { onExpand() }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.up")
                        Text("收起")
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 20).padding(.bottom, 14)
        }
    }
}

// MARK: - Field Row

struct FieldRowView: View {
    let field: FormField
    let fieldIndex: Int
    let isFocused: Bool
    let onUpdate: (String) -> Void
    let onFocus: (Bool) -> Void

    @State private var text: String = ""
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Label row
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(field.label).font(.subheadline).fontWeight(.medium)

                if field.prefillSources.contains(.profile) {
                    Image(systemName: "person.fill.checkmark")
                        .font(.caption2).foregroundStyle(.sfAccent)
                        .help("已从画像自动填写")
                }
                if field.prefillSources.contains(.gps) {
                    Image(systemName: "location.fill")
                        .font(.caption2).foregroundStyle(.sfInfo)
                }

                Spacer()

                // 为什么需要？
                if let help = field.helpText {
                    Menu {
                        Text(help).font(.callout)
                        if let privacy = field.privacyNote {
                            Divider()
                            Label(privacy, systemImage: "lock.shield").font(.caption)
                        }
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.caption).foregroundStyle(.sfInfo)
                    }
                }
            }

            // Input
            switch field.type {
            case .select, .multiSelect:
                PickerField(field: field, value: text, onUpdate: { newVal in
                    text = newVal
                    onUpdate(newVal)
                })

            case .date:
                DateField(field: field, value: text, onUpdate: { newVal in
                    text = newVal
                    onUpdate(newVal)
                })

            case .photo:
                PhotoField(field: field)

            default:
                SmartTextField(
                    placeholder: field.placeholder,
                    text: $text,
                    keyboardType: keyboardType,
                    isValid: field.isValid || text.isEmpty,
                    prefilled: field.prefillSources.contains(.profile)
                )
                .focused($isTextFieldFocused)
            }

            // Validation message
            if !text.isEmpty && !field.isValid {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill").font(.caption2)
                    Text(validationMessage).font(.caption)
                }
                .foregroundStyle(.sfWarning)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .onAppear { text = field.value ?? "" }
        .onChange(of: isTextFieldFocused) { _, focused in onFocus(focused) }
        .onChange(of: text) { _, newVal in onUpdate(newVal) }
    }

    private var keyboardType: UIKeyboardType {
        switch field.type {
        case .number:  .decimalPad
        case .phone:   .phonePad
        case .email:   .emailAddress
        default:       .default
        }
    }

    private var validationMessage: String {
        field.validationRules.first?.message ?? "请检查此字段"
    }
}

// MARK: - Smart TextField

struct SmartTextField: View {
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    var isValid: Bool
    var prefilled: Bool

    var body: some View {
        HStack(spacing: 8) {
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .font(.body)
                .padding(.vertical, 10)
            if !text.isEmpty {
                Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isValid ? .sfAccent : .sfWarning)
                    .font(.callout)
            }
        }
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(prefilled ? Color.sfAccent.opacity(0.05) : Color.gray.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(borderColor, lineWidth: text.isEmpty ? 0 : 1.5)
        )
    }

    private var borderColor: Color {
        if text.isEmpty { return .clear }
        return isValid ? .sfAccent : .sfWarning
    }
}

// MARK: - Picker Field

struct PickerField: View {
    let field: FormField
    let value: String
    let onUpdate: (String) -> Void

    var body: some View {
        Menu {
            ForEach(field.options ?? []) { option in
                Button(option.label) { onUpdate(option.label) }
            }
        } label: {
            HStack {
                Text(value.isEmpty ? field.placeholder : value)
                    .foregroundStyle(value.isEmpty ? .secondary : .primary)
                Spacer()
                Image(systemName: "chevron.down").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.gray.opacity(0.06)))
        }
    }
}

// MARK: - Date Field

struct DateField: View {
    let field: FormField
    let value: String
    let onUpdate: (String) -> Void
    @State private var date = Date()

    var body: some View {
        DatePicker(
            "",
            selection: $date,
            displayedComponents: .date
        )
        .datePickerStyle(.compact)
        .labelsHidden()
        .onChange(of: date) { _, newDate in
            let fm = DateFormatter()
            fm.dateFormat = "yyyy-MM-dd"
            onUpdate(fm.string(from: newDate))
        }
    }
}

// MARK: - Photo Field

struct PhotoField: View {
    let field: FormField
    @State private var showCamera = false

    var body: some View {
        Button { showCamera = true } label: {
            HStack {
                Image(systemName: "camera.fill").foregroundStyle(.sfPrimary)
                Text(field.placeholder).foregroundStyle(.secondary)
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14).padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                    .foregroundStyle(.sfPrimary.opacity(0.3))
            )
        }
    }
}
