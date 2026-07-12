import Foundation

// MARK: - Field Types

enum FieldType: String, Codable, CaseIterable {
    case text
    case number
    case email
    case phone
    case date
    case idCard          // 身份证号 — auto-parses gender/birthday
    case name
    case address
    case select          // 下拉单选
    case multiSelect     // 多选
    case photo           // 拍照上传
    case voice           // 语音输入
    case bankCard        // 银行卡号 — OCR-friendly
    case organizationCode // 统一社会信用代码
}

// MARK: - Validation Rule

struct ValidationRule: Codable, Identifiable {
    var id = UUID()
    let type: ValidationType
    let message: String

    enum ValidationType: String, Codable {
        case required
        case minLength(Int)
        case maxLength(Int)
        case regex(String)
        case idCardFormat
        case phoneFormat
        case emailFormat
    }
}

// 因为 enum with associated values 不直接 Codable，压缩为一个结构
extension ValidationRule {
    enum CodingKeys: String, CodingKey {
        case typeName, message, value
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let name = try c.decode(String.self, forKey: .typeName)
        message = try c.decode(String.self, forKey: .message)
        switch name {
        case "required":  type = .required
        case "idCard":    type = .idCardFormat
        case "phone":     type = .phoneFormat
        case "email":     type = .emailFormat
        case "minLength": let v = try c.decode(Int.self, forKey: .value); type = .minLength(v)
        case "maxLength": let v = try c.decode(Int.self, forKey: .value); type = .maxLength(v)
        case "regex":     let v = try c.decode(String.self, forKey: .value); type = .regex(v)
        default:          type = .required
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(message, forKey: .message)
        switch type {
        case .required:               try c.encode("required", forKey: .typeName)
        case .idCardFormat:           try c.encode("idCard",  forKey: .typeName)
        case .phoneFormat:            try c.encode("phone",   forKey: .typeName)
        case .emailFormat:            try c.encode("email",   forKey: .typeName)
        case .minLength(let v):       try c.encode("minLength", forKey: .typeName); try c.encode(v, forKey: .value)
        case .maxLength(let v):       try c.encode("maxLength", forKey: .typeName); try c.encode(v, forKey: .value)
        case .regex(let v):           try c.encode("regex",     forKey: .typeName); try c.encode(v, forKey: .value)
        }
    }
}

// MARK: - Select Option

struct SelectOption: Codable, Identifiable {
    var id = UUID()
    let label: String
    let value: String
    /// 选中此选项后的分支目标（可选 — 用于条件逻辑）
    var branchTarget: BranchCondition?
}

struct BranchCondition: Codable {
    let showCards: [String]   // 展示这些卡片
    let hideCards: [String]   // 隐藏这些卡片
}

// MARK: - Form Field

struct FormField: Codable, Identifiable {
    var id = UUID()
    let key: String            // 数据键名
    let label: String          // 显示标签
    let placeholder: String
    let type: FieldType
    let helpText: String?      // "为什么需要这个？"
    let privacyNote: String?   // 隐私说明
    var options: [SelectOption]? // type == select 时
    var defaultValue: String?  // 预填值（来自 PrefillEngine）
    var value: String?         // 用户填写的值
    var isValid: Bool = true
    var validationRules: [ValidationRule]

    // Auto-fill source hint
    enum PrefillSource: String, Codable {
        case gps, device, profile, ocr, crossForm, manual
    }
    var prefillSources: [PrefillSource] = []
}

// MARK: - Form Card (语义组)

struct FormCard: Codable, Identifiable {
    var id = UUID()
    let order: Int
    let title: String          // "③ 公积金账户"
    let subtitle: String?      // "请确认以下账户信息"
    let iconName: String       // SF Symbol name
    var fields: [FormField]
    var isCompleted: Bool {
        fields.allSatisfy { $0.value != nil && $0.value!.isEmpty == false && $0.isValid }
    }
    var isExpanded: Bool = false // UI state (not persisted)
}

// MARK: - Form Template

struct FormTemplate: Codable, Identifiable {
    var id = UUID()
    let name: String           // "住房公积金提取申请表"
    let category: TemplateCategory
    let description: String
    let iconName: String
    let estimatedMinutes: Int
    var cards: [FormCard]
    var outputFormat: OutputFormat

    enum TemplateCategory: String, Codable, CaseIterable {
        case government = "政务办事"
        case business   = "商务入驻"
        case finance    = "金融业务"
        case education  = "教育培训"
        case healthcare = "医疗健康"
        case custom     = "自定义"
    }

    enum OutputFormat: String, Codable {
        case pdf, email, api, print
    }
}

// MARK: - Form Session (进行中的填表)

struct FormSession: Codable, Identifiable {
    var id = UUID()
    let templateId: UUID
    var templateName: String
    var cards: [FormCard]
    var currentCardIndex: Int
    var startedAt: Date
    var lastSavedAt: Date
    var isCompleted: Bool = false

    var progress: Double {
        let total = cards.flatMap(\.fields).count
        guard total > 0 else { return 0 }
        let filled = cards.flatMap(\.fields).filter { $0.value != nil && !$0.value!.isEmpty }.count
        return Double(filled) / Double(total)
    }

    var completedCards: Int { cards.filter(\.isCompleted).count }
    var totalCards: Int { cards.count }
}

// MARK: - User Profile (安全画像)

struct UserProfile: Codable {
    var name: String?
    var idCard: String?
    var gender: String?
    var birthDate: String?
    var phone: String?
    var email: String?
    var addresses: [AddressItem] = []
    var bankCards: [BankCardItem] = []
    var companyName: String?
    var organizationCode: String?

    struct AddressItem: Codable, Identifiable {
        var id = UUID()
        let label: String
        let province: String
        let city: String
        let district: String
        let street: String
        let detail: String
    }

    struct BankCardItem: Codable, Identifiable {
        var id = UUID()
        let bankName: String
        let cardNumber: String
    }
}
