import Foundation

/// 模板加载服务 — 生产环境替换为远程模板库
final class TemplateService {
    static let shared = TemplateService()

    /// 5 个 MVP 模板
    func loadBuiltInTemplates() -> [FormTemplate] {
        return [
            housingFundTemplate,
            ecommerceTemplate,
            loanApplicationTemplate,
            visaApplicationTemplate,
            schoolRegistrationTemplate,
        ]
    }

    // MARK: - 模板 1：公积金提取

    private var housingFundTemplate: FormTemplate {
        FormTemplate(
            name: "住房公积金提取申请表",
            category: .government,
            description: "用于提取个人住房公积金账户余额",
            iconName: "building.columns.fill",
            estimatedMinutes: 3,
            cards: [
                FormCard(
                    order: 0, title: "个人信息", subtitle: nil,
                    iconName: "person.fill",
                    fields: [
                        field(key: "name", label: "姓名", placeholder: "请输入姓名", type: .name,
                              help: "用于核实申请人身份", privacy: "仅用于本次申请，不会共享"),
                        field(key: "idCard", label: "身份证号", placeholder: "18 位身份证号码", type: .idCard,
                              help: "公积金管理中心要求验证", privacy: "加密存储，提交后 30 天自动删除",
                              rules: [.init(type: .idCardFormat, message: "请输入正确的 18 位身份证号")]),
                        field(key: "phone", label: "手机号", placeholder: "11 位手机号", type: .phone,
                              help: "接收办理进度通知", privacy: nil),
                    ]
                ),
                FormCard(
                    order: 1, title: "公积金账户", subtitle: "请确认以下账户信息",
                    iconName: "creditcard.fill",
                    fields: [
                        field(key: "bankName", label: "开户银行", placeholder: "请选择开户银行",
                              type: .select,
                              options: [
                                option("招商银行", "cmb"),
                                option("工商银行", "icbc"),
                                option("建设银行", "ccb"),
                                option("农业银行", "abc"),
                                option("中国银行", "boc"),
                              ]),
                        field(key: "accountNumber", label: "公积金账号", placeholder: "请输入账号", type: .text,
                              help: "通常为工资卡所属银行的公积金联名卡号"),
                    ]
                ),
                FormCard(
                    order: 2, title: "提取信息", subtitle: nil,
                    iconName: "arrow.down.doc.fill",
                    fields: [
                        field(key: "extractReason", label: "提取原因", placeholder: "请选择",
                              type: .select,
                              options: [
                                option("购房", "house"),
                                option("租房", "rent"),
                                option("偿还贷款", "loan"),
                                option("退休", "retire"),
                                option("离职", "quit"),
                              ]),
                        field(key: "extractAmount", label: "提取金额（元）", placeholder: "请输入金额",
                              type: .number,
                              rules: [.init(type: .minLength(1), message: "请输入提取金额")]),
                    ]
                ),
                FormCard(
                    order: 3, title: "上传材料", subtitle: "请拍照上传以下材料",
                    iconName: "camera.fill",
                    fields: [
                        field(key: "idCardPhoto", label: "身份证照片", placeholder: "拍照上传",
                              type: .photo, help: "需清晰可见，四角完整"),
                        field(key: "bankCardPhoto", label: "银行卡照片", placeholder: "拍照上传",
                              type: .photo, help: "用于核实收款账户"),
                    ]
                ),
            ],
            outputFormat: .pdf
        )
    }

    // MARK: - 模板 2：电商入驻

    private var ecommerceTemplate: FormTemplate {
        FormTemplate(
            name: "电商平台商家入驻",
            category: .business,
            description: "在电商平台开设店铺所需的入驻信息",
            iconName: "storefront.fill",
            estimatedMinutes: 5,
            cards: [
                FormCard(
                    order: 0, title: "主体类型", subtitle: nil,
                    iconName: "building.2.fill",
                    fields: [
                        field(key: "entityType", label: "入驻主体", placeholder: "请选择", type: .select,
                              options: [
                                option("个人", "individual"),
                                option("企业", "enterprise"),
                                option("个体工商户", "sole"),
                              ]),
                    ]
                ),
                FormCard(
                    order: 1, title: "身份信息", subtitle: nil,
                    iconName: "person.text.rectangle.fill",
                    fields: [
                        field(key: "contactName", label: "联系人姓名", placeholder: "请输入", type: .name),
                        field(key: "contactPhone", label: "手机号", placeholder: "11 位手机号", type: .phone),
                        field(key: "idCard", label: "身份证号", placeholder: "18 位", type: .idCard),
                    ]
                ),
                FormCard(
                    order: 2, title: "经营信息", subtitle: nil,
                    iconName: "bag.fill",
                    fields: [
                        field(key: "shopName", label: "店铺名称", placeholder: "起一个响亮的名字", type: .text),
                        field(key: "category", label: "主营类目", placeholder: "请选择", type: .select,
                              options: [
                                option("服装", "clothing"),
                                option("食品", "food"),
                                option("数码", "digital"),
                                option("家居", "home"),
                                option("美妆", "beauty"),
                              ]),
                    ]
                ),
                FormCard(
                    order: 3, title: "结算账户", subtitle: nil,
                    iconName: "banknote.fill",
                    fields: [
                        field(key: "bankCard", label: "银行卡号", placeholder: "请输入", type: .bankCard),
                        field(key: "bankName", label: "开户银行", placeholder: "请选择", type: .select,
                              options: [
                                option("招商银行", "cmb"),
                                option("工商银行", "icbc"),
                                option("建设银行", "ccb"),
                              ]),
                    ]
                ),
            ],
            outputFormat: .api
        )
    }

    // MARK: - 模板 3：贷款申请

    private var loanApplicationTemplate: FormTemplate {
        FormTemplate(
            name: "个人消费贷款申请",
            category: .finance,
            description: "申请个人消费信用贷款",
            iconName: "dollarsign.circle.fill",
            estimatedMinutes: 4,
            cards: [
                FormCard(
                    order: 0, title: "基本信息", subtitle: nil,
                    iconName: "person.fill",
                    fields: [
                        field(key: "name", label: "姓名", placeholder: "请输入", type: .name),
                        field(key: "idCard", label: "身份证号", placeholder: "18 位", type: .idCard),
                        field(key: "phone", label: "手机号", placeholder: "请输入", type: .phone),
                    ]
                ),
                FormCard(
                    order: 1, title: "工作信息", subtitle: nil,
                    iconName: "briefcase.fill",
                    fields: [
                        field(key: "company", label: "工作单位", placeholder: "请输入公司全称", type: .text),
                        field(key: "position", label: "职位", placeholder: "请输入", type: .text),
                        field(key: "monthlyIncome", label: "月收入（元）", placeholder: "请输入", type: .number,
                              privacy: "仅用于评估还款能力"),
                    ]
                ),
                FormCard(
                    order: 2, title: "贷款详情", subtitle: nil,
                    iconName: "chart.bar.fill",
                    fields: [
                        field(key: "loanAmount", label: "贷款金额（元）", placeholder: "请输入", type: .number),
                        field(key: "loanTerm", label: "贷款期限", placeholder: "请选择", type: .select,
                              options: [
                                option("6 个月", "6"),
                                option("12 个月", "12"),
                                option("24 个月", "24"),
                                option("36 个月", "36"),
                              ]),
                        field(key: "purpose", label: "贷款用途", placeholder: "请选择", type: .select,
                              options: [
                                option("装修", "renovation"),
                                option("教育", "education"),
                                option("旅游", "travel"),
                                option("医疗", "medical"),
                                option("其他消费", "other"),
                              ]),
                    ]
                ),
            ],
            outputFormat: .api
        )
    }

    // MARK: - 模板 4：签证申请

    private var visaApplicationTemplate: FormTemplate {
        FormTemplate(
            name: "出境签证申请表",
            category: .government,
            description: "申请出境旅游/商务签证",
            iconName: "airplane.departure",
            estimatedMinutes: 5,
            cards: [
                FormCard(
                    order: 0, title: "申请人信息", subtitle: nil,
                    iconName: "person.fill",
                    fields: [
                        field(key: "name", label: "中文姓名", placeholder: "请输入", type: .name),
                        field(key: "nameEn", label: "拼音姓名", placeholder: "如 ZHANG SAN", type: .text),
                        field(key: "idCard", label: "身份证号", placeholder: "18 位", type: .idCard),
                        field(key: "passport", label: "护照号码", placeholder: "请输入", type: .text),
                    ]
                ),
                FormCard(
                    order: 1, title: "旅行信息", subtitle: nil,
                    iconName: "globe.asia.australia.fill",
                    fields: [
                        field(key: "destination", label: "目的地国家", placeholder: "请选择", type: .select,
                              options: [
                                option("日本", "jp"),
                                option("韩国", "kr"),
                                option("新加坡", "sg"),
                                option("泰国", "th"),
                                option("美国", "us"),
                                option("英国", "uk"),
                              ]),
                        field(key: "departDate", label: "出发日期", placeholder: "请选择", type: .date),
                        field(key: "returnDate", label: "返回日期", placeholder: "请选择", type: .date),
                    ]
                ),
                FormCard(
                    order: 2, title: "紧急联系人", subtitle: nil,
                    iconName: "phone.fill.connection",
                    fields: [
                        field(key: "emergencyName", label: "联系人姓名", placeholder: "请输入", type: .name),
                        field(key: "emergencyPhone", label: "联系人电话", placeholder: "请输入", type: .phone),
                        field(key: "emergencyRelation", label: "与申请人关系", placeholder: "请选择", type: .select,
                              options: [
                                option("配偶", "spouse"),
                                option("父母", "parent"),
                                option("子女", "child"),
                                option("朋友", "friend"),
                              ]),
                    ]
                ),
            ],
            outputFormat: .pdf
        )
    }

    // MARK: - 模板 5：入学报名

    private var schoolRegistrationTemplate: FormTemplate {
        FormTemplate(
            name: "中小学入学报名表",
            category: .education,
            description: "适龄儿童入学信息登记",
            iconName: "graduationcap.fill",
            estimatedMinutes: 4,
            cards: [
                FormCard(
                    order: 0, title: "学生信息", subtitle: nil,
                    iconName: "person.fill",
                    fields: [
                        field(key: "studentName", label: "学生姓名", placeholder: "请输入", type: .name),
                        field(key: "studentGender", label: "性别", placeholder: "请选择", type: .select,
                              options: [option("男", "male"), option("女", "female")]),
                        field(key: "birthDate", label: "出生日期", placeholder: "请选择", type: .date),
                    ]
                ),
                FormCard(
                    order: 1, title: "监护人信息", subtitle: nil,
                    iconName: "person.2.fill",
                    fields: [
                        field(key: "guardianName", label: "监护人姓名", placeholder: "请输入", type: .name),
                        field(key: "guardianPhone", label: "联系电话", placeholder: "请输入", type: .phone),
                        field(key: "guardianRelation", label: "与学生关系", placeholder: "请选择", type: .select,
                              options: [
                                option("父亲", "father"),
                                option("母亲", "mother"),
                                option("其他", "other"),
                              ]),
                    ]
                ),
                FormCard(
                    order: 2, title: "户籍与住址", subtitle: "用于学区划分",
                    iconName: "house.fill",
                    fields: [
                        field(key: "address", label: "户籍地址", placeholder: "省/市/区/街道/详细地址", type: .text,
                              help: "需与户口本一致", prefill: [.gps]),
                        field(key: "liveAddress", label: "现居住地址", placeholder: "如与户籍一致可跳过", type: .text,
                              prefill: [.gps]),
                    ]
                ),
                FormCard(
                    order: 3, title: "上传材料", subtitle: nil,
                    iconName: "doc.fill",
                    fields: [
                        field(key: "birthCert", label: "出生证明", placeholder: "拍照上传", type: .photo),
                        field(key: "householdBook", label: "户口本", placeholder: "拍照上传", type: .photo),
                        field(key: "vaccineCert", label: "预防接种证", placeholder: "拍照上传", type: .photo),
                    ]
                ),
            ],
            outputFormat: .pdf
        )
    }

    // MARK: - Helper Builders

    private func field(
        key: String, label: String, placeholder: String, type: FieldType,
        help: String? = nil, privacy: String? = nil,
        options: [SelectOption]? = nil,
        rules: [ValidationRule]? = nil,
        prefill: [FormField.PrefillSource] = []
    ) -> FormField {
        FormField(
            key: key, label: label, placeholder: placeholder, type: type,
            helpText: help, privacyNote: privacy,
            options: options,
            validationRules: rules ?? [.init(type: .required, message: "此字段为必填项")],
            prefillSources: prefill
        )
    }

    private func option(_ label: String, _ value: String) -> SelectOption {
        SelectOption(label: label, value: value)
    }
}
