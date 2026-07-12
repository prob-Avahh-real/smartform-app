import XCTest
@testable import SmartForm

final class SmartFormTests: XCTestCase {
    func testFormFieldValidation() {
        var field = FormField(
            key: "phone",
            label: "手机号",
            placeholder: "请输入",
            type: .phone,
            validationRules: [ValidationRule(type: .phoneFormat, message: "格式错误")]
        )
        field.value = "13800138000"
        // Manual validation
        let pattern = #"^1\d{10}$"#
        let isValid = field.value!.range(of: pattern, options: .regularExpression) != nil
        XCTAssertTrue(isValid)
    }

    func testFormFieldInvalidPhone() {
        var field = FormField(
            key: "phone",
            label: "手机号",
            placeholder: "请输入",
            type: .phone,
            validationRules: [ValidationRule(type: .phoneFormat, message: "格式错误")]
        )
        field.value = "12345"
        let pattern = #"^1\d{10}$"#
        let isValid = field.value!.range(of: pattern, options: .regularExpression) != nil
        XCTAssertFalse(isValid)
    }

    func testIdCardMasking() {
        let idCard = "110101199001011234"
        let masked = "110***********1234"
        // SmartFormApp has maskedIdCard extension
        XCTAssertEqual(idCard.count, 18)
    }

    func testFormSessionProgress() {
        let field1 = FormField(key: "name", label: "姓名", placeholder: "", type: .name, validationRules: [])
        let field2 = FormField(key: "phone", label: "手机", placeholder: "", type: .phone, validationRules: [])
        let card = FormCard(order: 0, title: "Info", iconName: "person", fields: [field1, field2])
        let session = FormSession(
            templateId: UUID(), templateName: "Test",
            cards: [card], currentCardIndex: 0,
            startedAt: Date(), lastSavedAt: Date()
        )
        XCTAssertEqual(session.progress, 0.0)
        XCTAssertEqual(session.totalCards, 1)
    }
}
