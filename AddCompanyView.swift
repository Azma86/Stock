//
//  AddCompanyView.swift
//  Stock
//
//  Created by Mitsuki Kimura on 2026/08/01.
//

//
//  AddCompanyView.swift
//  就勝Stock
//
//  企業一覧画面（CompanyListView.swift）右上「＋」から開く新規企業追加モーダル。
//

import SwiftUI
import SwiftData
import PhotosUI

// MARK: - タブ定義

private enum AddCompanyTab: String, CaseIterable, Identifiable {
    case basic = "基本情報"
    case flow = "選考フロー"
    case preparation = "選考対策"

    var id: String { rawValue }
}

// MARK: - AddCompanyView

struct AddCompanyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab: AddCompanyTab = .basic

    // --- 基本情報 ---
    @State private var companyName: String = ""
    @State private var aspirationLevel: AspirationLevel = .circle
    @State private var overallStatus: SelectionOverallStatus = .considering

    @State private var industryTags: [String] = []
    @State private var jobTypeTags: [String] = []
    @State private var welfareTags: [String] = []

    @State private var companyURL: String = ""
    @State private var myPageURL: String = ""
    
    // マイページID・会員番号を要件定義通り分離
    @State private var myPageID: String = ""
    @State private var memberNumber: String = ""

    @State private var addresses: [AddressDraft] = [AddressDraft()]
    @State private var contacts: [ContactDraft] = [ContactDraft()]

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?

    @State private var remarks: String = ""

    // --- 選考フロー ---
    @State private var processDrafts: [ProcessDraft] = []

    // --- 選考対策 ---
    @State private var selfPR: String = ""
    @State private var selfPRTargetLength: Int = 0
    @State private var gakuchika: String = ""
    @State private var gakuchikaTargetLength: Int = 0
    @State private var motivationReason: String = ""
    @State private var motivationTargetLength: Int = 0
    @State private var preparationRemarks: String = ""

    // --- エラー表示 ---
    @State private var showingSaveError = false

    // 候補タグ（初期候補。ユーザーは自由に追加可能）
    private static let industrySuggestions = [
        "IT・通信", "メーカー", "商社", "金融", "コンサルティング",
        "広告・マスコミ", "小売・流通", "サービス", "医療・福祉", "官公庁・団体"
    ]
    private static let jobTypeSuggestions = [
        "総合職", "エンジニア", "営業", "企画・マーケティング", "事務・管理",
        "研究・開発", "デザイナー", "コンサルタント"
    ]
    private static let welfareSuggestions = [
        "住宅手当", "リモートワーク可", "フレックスタイム制", "副業可",
        "退職金制度", "社員食堂", "産休・育休制度", "資格取得支援"
    ]

    private var isSaveDisabled: Bool {
        companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("タブ", selection: $selectedTab) {
                    ForEach(AddCompanyTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                Group {
                    switch selectedTab {
                    case .basic:
                        basicInfoForm
                    case .flow:
                        selectionFlowForm
                    case .preparation:
                        preparationForm
                    }
                }
            }
            .navigationTitle("新規企業を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") { save() }
                        .fontWeight(.semibold)
                        .disabled(isSaveDisabled)
                }
            }
            .alert("保存に失敗しました", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("入力内容を確認して、もう一度お試しください。")
            }
        }
    }

    // MARK: - 基本情報タブ

    private var basicInfoForm: some View {
        Form {
            Section("基本情報") {
                TextField("社名（必須）", text: $companyName)

                Picker("選考ステータス", selection: $overallStatus) {
                    ForEach(SelectionOverallStatus.allCases) { status in
                        Text(status.rawValue).tag(status)
                    }
                }
            }

            Section("志望度") {
                AspirationLevelPicker(selection: $aspirationLevel)
                    .padding(.vertical, 4)
            }

            Section("業界") {
                TagChipPickerView(
                    placeholder: "業界を追加",
                    suggestedTags: Self.industrySuggestions,
                    selectedTags: $industryTags
                )
            }

            Section("職種") {
                TagChipPickerView(
                    placeholder: "職種を追加",
                    suggestedTags: Self.jobTypeSuggestions,
                    selectedTags: $jobTypeTags
                )
            }

            Section("リンク・ID") {
                TextField("企業HP URL", text: $companyURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("マイページ URL", text: $myPageURL)
                    .keyboardType(.URL)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("マイページID", text: $myPageID)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                TextField("会員番号", text: $memberNumber)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }

            Section("住所") {
                addressCards
            }

            Section("福利厚生") {
                TagChipPickerView(
                    placeholder: "福利厚生を追加",
                    suggestedTags: Self.welfareSuggestions,
                    selectedTags: $welfareTags
                )
            }

            Section("連絡先") {
                contactCards
            }

            Section("添付画像") {
                imageContent
            }

            Section("備考") {
                TextEditor(text: $remarks)
                    .frame(minHeight: 100)
            }
        }
    }

    @ViewBuilder
    private var addressCards: some View {
        ForEach($addresses) { $address in
            VStack(alignment: .leading, spacing: 6) {
                TextField("本社・支店名など", text: $address.label)
                Divider()
                TextField("住所", text: $address.addressText)
            }
            .padding(.vertical, 4)
        }
        .onDelete { indexSet in
            addresses.remove(atOffsets: indexSet)
        }

        Button {
            addresses.append(AddressDraft())
        } label: {
            Label("住所を追加", systemImage: "plus.circle")
        }
    }

    @ViewBuilder
    private var contactCards: some View {
        ForEach($contacts) { $contact in
            VStack(alignment: .leading, spacing: 6) {
                TextField("担当者名・部署など", text: $contact.label)

                Picker("種別", selection: $contact.linkType) {
                    ForEach(ContactLinkType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)

                TextField("電話番号・メールアドレス・URLなど", text: $contact.value)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
            .padding(.vertical, 4)
        }
        .onDelete { indexSet in
            contacts.remove(atOffsets: indexSet)
        }

        Button {
            contacts.append(ContactDraft())
        } label: {
            Label("連絡先を追加", systemImage: "plus.circle")
        }
    }

    private var imageContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button {
                        selectedImageData = nil
                        selectedPhotoItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 6, y: -6)
                }
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label(selectedImageData == nil ? "画像を選択" : "画像を変更", systemImage: "photo.on.rectangle")
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    guard let newItem else {
                        await MainActor.run {
                            selectedImageData = nil
                        }
                        return
                    }
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        let compressed = compressedImageData(from: data)
                        await MainActor.run {
                            selectedImageData = compressed
                        }
                    }
                }
            }

            Text("無料版は1枚まで添付できます（プレミアムで最大10枚）")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - 選考フロータブ

    private var selectionFlowForm: some View {
        Form {
            Section {
                Text("面接・テスト・書類提出など、選考プロセスのステップを追加できます。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(processDrafts.enumerated()), id: \.element.id) { index, draft in
                Section("プロセス \(index + 1)") {
                    Picker("大分類", selection: processBinding(for: draft.id).largeCategory) {
                        ForEach(LargeCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }

                    Picker("中分類", selection: processBinding(for: draft.id).middleCategory) {
                        ForEach(MiddleCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .onChange(of: draft.middleCategory) { _, newValue in
                        processBinding(for: draft.id).wrappedValue.smallCategory = newValue.defaultSmallCategories.first ?? ""
                    }

                    Picker("小分類", selection: processBinding(for: draft.id).smallCategory) {
                        ForEach(draft.middleCategory.defaultSmallCategories, id: \.self) { small in
                            Text(small).tag(small)
                        }
                    }

                    Picker("ステータス", selection: processBinding(for: draft.id).status) {
                        ForEach(ProcessStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }

                    Button(role: .destructive) {
                        removeProcess(draft.id)
                    } label: {
                        Label("このプロセスを削除", systemImage: "trash")
                    }
                }
            }

            Section {
                Button {
                    var newDraft = ProcessDraft()
                    newDraft.smallCategory = newDraft.middleCategory.defaultSmallCategories.first ?? ""
                    processDrafts.append(newDraft)
                } label: {
                    Label("選考プロセスを追加", systemImage: "plus.circle")
                }
            }
        }
    }

    // MARK: - 選考対策タブ

    private var preparationForm: some View {
        Form {
            preparationField(
                title: "自己PR",
                text: $selfPR,
                targetLength: $selfPRTargetLength
            )
            preparationField(
                title: "学生時代に力を入れたこと（ガクチカ）",
                text: $gakuchika,
                targetLength: $gakuchikaTargetLength
            )
            preparationField(
                title: "志望理由",
                text: $motivationReason,
                targetLength: $motivationTargetLength
            )

            Section("その他備考") {
                TextEditor(text: $preparationRemarks)
                    .frame(minHeight: 100)
            }
        }
    }

    private func preparationField(title: String, text: Binding<String>, targetLength: Binding<Int>) -> some View {
        Section(title) {
            TextEditor(text: text)
                .frame(minHeight: 120)

            HStack {
                Text("\(text.wrappedValue.count)文字")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Stepper(
                    "目標: \(targetLength.wrappedValue == 0 ? "未設定" : "\(targetLength.wrappedValue)文字")",
                    value: targetLength,
                    in: 0...2000,
                    step: 50
                )
                .font(.caption)
            }
        }
    }

    private func processBinding(for id: UUID) -> Binding<ProcessDraft> {
        guard let index = processDrafts.firstIndex(where: { $0.id == id }) else {
            return .constant(ProcessDraft())
        }
        return $processDrafts[index]
    }

    private func removeProcess(_ id: UUID) {
        processDrafts.removeAll { $0.id == id }
    }

    private func compressedImageData(from data: Data) -> Data? {
        guard let uiImage = UIImage(data: data) else { return data }
        return uiImage.jpegData(compressionQuality: 0.8)
    }

    private func save() {
        let trimmedName = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let newCompany = CompanyProfile(
            companyName: trimmedName,
            industryTags: industryTags,
            jobTypeTags: jobTypeTags,
            aspirationLevel: aspirationLevel,
            companyURL: companyURL,
            myPageURL: myPageURL,
            myPageID: myPageID,
            memberNumber: memberNumber,
            welfareTags: welfareTags,
            remarks: remarks,
            overallStatus: overallStatus
        )
        
        modelContext.insert(newCompany)

        for draft in addresses where !draft.addressText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let address = Address(
                label: draft.label.isEmpty ? "住所" : draft.label,
                addressText: draft.addressText
            )
            modelContext.insert(address)
            address.company = newCompany
        }

        for draft in contacts where !draft.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let contact = ContactInfo(
                label: draft.label,
                linkType: draft.linkType,
                value: draft.value
            )
            modelContext.insert(contact)
            contact.company = newCompany
        }

        if let selectedImageData {
            let image = AttachedImage(imageData: selectedImageData)
            modelContext.insert(image)
            image.company = newCompany
        }

        for (index, draft) in processDrafts.enumerated() {
            let process = SelectionProcess(
                largeCategory: draft.largeCategory,
                middleCategory: draft.middleCategory,
                smallCategory: draft.smallCategory,
                status: draft.status,
                sequenceNumber: index + 1,
                sortOrder: index
            )
            modelContext.insert(process)
            process.company = newCompany
        }

        let hasPreparationContent = !selfPR.isEmpty || !gakuchika.isEmpty
            || !motivationReason.isEmpty || !preparationRemarks.isEmpty
        if hasPreparationContent {
            let note = SelectionPreparationNote(
                selfPR: selfPR,
                selfPRTargetLength: selfPRTargetLength,
                gakuchika: gakuchika,
                gakuchikaTargetLength: gakuchikaTargetLength,
                motivationReason: motivationReason,
                motivationTargetLength: motivationTargetLength,
                remarks: preparationRemarks
            )
            modelContext.insert(note)
            note.company = newCompany
            newCompany.preparationNote = note
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            showingSaveError = true
        }
    }
}

// MARK: - 入力用ドラフトモデル

private struct AddressDraft: Identifiable {
    let id = UUID()
    var label: String = ""
    var addressText: String = ""
}

private struct ContactDraft: Identifiable {
    let id = UUID()
    var label: String = ""
    var linkType: ContactLinkType = .phone
    var value: String = ""
}

private struct ProcessDraft: Identifiable {
    let id = UUID()
    var largeCategory: LargeCategory = .mainSelection
    var middleCategory: MiddleCategory = .interview
    var smallCategory: String = MiddleCategory.interview.defaultSmallCategories.first ?? ""
    var status: ProcessStatus = .notReached
}

// MARK: - 共通コンポーネント

struct AspirationLevelPicker: View {
    @Binding var selection: AspirationLevel
    private let levels = AspirationLevel.allCases.sorted(by: { $0.rawValue > $1.rawValue })

    var body: some View {
        HStack(spacing: 12) {
            ForEach(levels) { level in
                Button {
                    selection = level
                } label: {
                    Text(level.symbol)
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selection == level ? Color.orange.opacity(0.2) : Color.gray.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selection == level ? Color.orange : Color.clear, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .foregroundStyle(.primary)
            }
        }
    }
}

struct TagChipPickerView: View {
    let placeholder: String
    let suggestedTags: [String]
    @Binding var selectedTags: [String]
    @State private var newTagText: String = ""

    private var displayTags: [String] {
        var tags = suggestedTags
        for tag in selectedTags where !tags.contains(tag) {
            tags.append(tag)
        }
        return tags
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            FlowLayout(spacing: 8) {
                ForEach(displayTags, id: \.self) { tag in
                    chip(for: tag)
                }
            }

            HStack(spacing: 8) {
                TextField(placeholder, text: $newTagText)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(addCustomTag)
                Button("追加", action: addCustomTag)
                    .disabled(newTagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private func chip(for tag: String) -> some View {
        let isSelected = selectedTags.contains(tag)
        return Button {
            toggle(tag)
        } label: {
            Text(tag)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(isSelected ? Color.blue : Color.gray.opacity(0.15))
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func toggle(_ tag: String) {
        if let index = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    private func addCustomTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if !selectedTags.contains(trimmed) {
            selectedTags.append(trimmed)
        }
        newTagText = ""
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowWidth + size.width > maxWidth, rowWidth > 0 {
                totalHeight += rowHeight + spacing
                totalWidth = max(totalWidth, rowWidth)
                rowWidth = 0
                rowHeight = 0
            }
            rowWidth += size.width + (rowWidth == 0 ? 0 : spacing)
            rowHeight = max(rowHeight, size.height)
        }
        totalHeight += rowHeight
        totalWidth = max(totalWidth, rowWidth)

        let resolvedWidth = maxWidth.isFinite ? maxWidth : totalWidth
        return CGSize(width: resolvedWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
