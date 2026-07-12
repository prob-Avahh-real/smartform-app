import SwiftUI
import Vision
import UniformTypeIdentifiers

/// 身份证 OCR 服务 — 使用 Apple Vision 框架实现离线识别
@MainActor
final class OCRService: ObservableObject {
    @Published var isProcessing = false

    enum OCRResult {
        case idCard(name: String, gender: String, birthDate: String, idNumber: String, address: String)
        case businessLicense(companyName: String, creditCode: String, legalPerson: String)
        case bankCard(cardNumber: String)
    }

    /// 从图片识别身份证信息
    func recognizeIDCard(from image: UIImage) async throws -> OCRResult? {
        isProcessing = true
        defer { isProcessing = false }

        guard let cgImage = image.cgImage else { return nil }

        // 使用 Vision 进行文字识别
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.recognitionLanguages = ["zh-Hans", "zh-Hant"]
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        try handler.perform([request])

        guard let observations = request.results else { return nil }

        // 提取所有识别文字
        let texts = observations.compactMap { obs -> String? in
            guard let candidate = obs.topCandidates(1).first else { return nil }
            return candidate.string
        }

        // 从识别文字中提取结构化信息
        return parseIDCardInfo(from: texts)
    }

    private func parseIDCardInfo(from texts: [String]) -> OCRResult? {
        var name: String?
        var gender: String?
        var birthDate: String?
        var idNumber: String?
        var address: String?

        for text in texts {
            let t = text.trimmingCharacters(in: .whitespaces)

            // 姓名：2-4个中文字符，前面有"姓名"或单独出现
            if t.contains("姓名") {
                name = t.replacingOccurrences(of: "姓名", with: "").trimmingCharacters(in: .whitespaces)
            } else if t.count >= 2 && t.count <= 4 && t.allSatisfy({ $0.isCJK }) && name == nil {
                // 可能为姓名（谨慎判断）
                let possibleNames = ["张三", "李四"] // 排除常见占位符
                if !possibleNames.contains(t) {
                    name = t
                }
            }

            // 身份证号：18位
            if t.range(of: #"^\d{17}[\dXx]$"#, options: .regularExpression) != nil {
                idNumber = t.uppercased()
                // 从身份证号解析性别和出生日期
                if idNumber!.count == 18 {
                    let start = idNumber!.index(idNumber!.startIndex, offsetBy: 6)
                    let end = idNumber!.index(start, offsetBy: 8)
                    let dateStr = String(idNumber![start..<end])
                    let fm = DateFormatter()
                    fm.dateFormat = "yyyyMMdd"
                    if let date = fm.date(from: dateStr) {
                        let out = DateFormatter()
                        out.dateFormat = "yyyy年MM月dd日"
                        birthDate = out.string(from: date)
                    }
                    let genderDigit = Int(String(idNumber![idNumber!.index(idNumber!.startIndex, offsetBy: 16)])) ?? 0
                    gender = genderDigit % 2 == 0 ? "女" : "男"
                }
            }

            // 性别
            if t.contains("性别") {
                let v = t.replacingOccurrences(of: "性别", with: "").trimmingCharacters(in: .whitespaces)
                if v == "男" || v == "女" { gender = v }
            } else if t == "男" || t == "女" {
                gender = t
            }

            // 地址
            if (t.contains("住址") || t.contains("地址")) && t.count > 5 {
                address = t.replacingOccurrences(of: "住址", with: "")
                    .replacingOccurrences(of: "地址", with: "")
                    .trimmingCharacters(in: .whitespaces)
            }
        }

        guard let n = name, let idn = idNumber else { return nil }
        return .idCard(
            name: n,
            gender: gender ?? "未知",
            birthDate: birthDate ?? "未知",
            idNumber: idn,
            address: address ?? ""
        )
    }
}

/// 智能预填引擎
final class PrefillEngine {
    private var profile: UserProfile

    init(profile: UserProfile) {
        self.profile = profile
    }

    func prefill(fields: inout [FormField]) -> Int {
        var filled = 0
        for i in fields.indices {
            let value: String? = switch fields[i].type {
            case .name:     profile.name
            case .idCard:   profile.idCard
            case .phone:    profile.phone
            case .email:    profile.email
            case .bankCard: profile.bankCards.first?.cardNumber
            default:        nil
            }
            if let v = value {
                fields[i].value = v
                fields[i].prefillSources.append(.profile)
                filled += 1
            }
        }
        return filled
    }

    func updateProfile(field: FormField) {
        guard let value = field.value else { return }
        switch field.type {
        case .name:           profile.name = value
        case .idCard:         profile.idCard = value
        case .phone:          profile.phone = value
        case .email:          profile.email = value
        default:              break
        }
    }
}
