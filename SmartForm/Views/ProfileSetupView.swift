import SwiftUI
import PhotosUI

/// 用户安全画像初始化 — OCR 扫描身份证
struct ProfileSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var scannedImage: UIImage?
    @State private var isScanning = false

    @State private var name = ""
    @State private var gender = ""
    @State private var birthDate = ""
    @State private var idCard = ""
    @State private var phone = ""
    @State private var email = ""

    let onSave: (UserProfile) -> Void

    private let ocrService = OCRService()

    var body: some View {
        NavigationStack {
            Form {
                // OCR Section
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            if let image = scannedImage {
                                Image(uiImage: image)
                                    .resizable().scaledToFit()
                                    .frame(height: 180)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    VStack(spacing: 10) {
                                        Image(systemName: "doc.text.viewfinder")
                                            .font(.system(size: 40))
                                            .foregroundStyle(.sfPrimary)
                                        Text("拍照识别身份证")
                                            .font(.subheadline).foregroundStyle(.sfPrimary)
                                        Text("自动提取姓名、身份证号等信息")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 30)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [6]))
                                            .foregroundStyle(.sfPrimary.opacity(0.3))
                                    )
                                }
                            }

                            if isScanning {
                                ProgressView("识别中...")
                            }
                        }
                        Spacer()
                    }
                }

                // Manual Entry
                Section("个人信息") {
                    LabeledContent("姓名") { TextField("请输入", text: $name) }
                    LabeledContent("性别") {
                        Picker("", selection: $gender) {
                            Text("请选择").tag("")
                            Text("男").tag("男")
                            Text("女").tag("女")
                        }
                    }
                    LabeledContent("出生日期") { TextField("如 1990年01月01日", text: $birthDate) }
                    LabeledContent("身份证号") { TextField("18位", text: $idCard).keyboardType(.numberPad) }
                    LabeledContent("手机号") { TextField("11位", text: $phone).keyboardType(.phonePad) }
                    LabeledContent("邮箱") { TextField("请输入", text: $email).keyboardType(.emailAddress) }
                }

                // Privacy note
                Section {
                    HStack {
                        Image(systemName: "lock.shield.fill").foregroundStyle(.sfAccent)
                        Text("以上信息仅存储在您的设备中，未经授权不会上传或共享。")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("创建安全画像")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("跳过") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let profile = UserProfile(
                            name: name.isEmpty ? nil : name,
                            idCard: idCard.isEmpty ? nil : idCard,
                            gender: gender.isEmpty ? nil : gender,
                            birthDate: birthDate.isEmpty ? nil : birthDate,
                            phone: phone.isEmpty ? nil : phone,
                            email: email.isEmpty ? nil : email
                        )
                        onSave(profile)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
            .onChange(of: selectedPhoto) { _, newItem in
                guard let item = newItem else { return }
                Task {
                    isScanning = true
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        scannedImage = image
                        if let result = try? await ocrService.recognizeIDCard(from: image) {
                            fillFromOCR(result)
                        }
                    }
                    isScanning = false
                }
            }
        }
    }

    private func fillFromOCR(_ result: OCRService.OCRResult) {
        if case .idCard(let n, let g, let b, let id, let _) = result {
            name = n
            gender = g
            birthDate = b
            idCard = id
        }
    }
}

// MARK: - Form Preview View

struct FormPreviewView: View {
    let session: FormSession
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.sfAccent)
                        Text("所有信息已填写完毕").font(.title3).fontWeight(.bold)
                        Text("请核对以下信息").foregroundStyle(.secondary)
                    }
                    .padding(.top, 24)

                    // Field summary
                    ForEach(session.cards) { card in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(card.title).font(.headline)
                                .padding(.horizontal, 16)

                            ForEach(card.fields) { field in
                                HStack {
                                    Text(field.label).foregroundStyle(.secondary)
                                    Spacer()
                                    Text(field.value ?? "-")
                                        .fontWeight(.medium)
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption).foregroundStyle(.sfAccent)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 10)
                                .background(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .background(Color.sfBg)
            .navigationTitle("预览")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("返回修改") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button(action: onSubmit) {
                        HStack {
                            Image(systemName: "paperplane.fill")
                            Text("提交表单")
                        }
                        .font(.headline).foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.sfAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)

                    HStack(spacing: 20) {
                        Label("生成 PDF", systemImage: "doc.fill")
                        Label("发送邮件", systemImage: "envelope.fill")
                        Label("打印", systemImage: "printer.fill")
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                .background(.regularMaterial)
            }
        }
    }
}
