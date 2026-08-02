//
//  EditCompanyView.swift
//  Stock
//
//  Created by Mitsuki Kimura on 2026/08/01.
//

import SwiftUI
import SwiftData
import PhotosUI

private enum EditCompanyTab: String, CaseIterable, Identifiable {
    case basic = "基本情報"
    case flow = "選考フロー"
    case preparation = "選考対策"

    var id: String { rawValue }
}

struct EditCompanyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Bindable var company: CompanyProfile

    @State private var selectedTab: EditCompanyTab = .basic

    // --- 基本情報 ---
    @State private var companyName: String = ""
    @State private var aspirationLevel: AspirationLevel = .circle
    @State private var overallStatus: SelectionOverallStatus = .considering
    @State private var industryTags: [String] = []
    @State private var jobTypeTags: [String] = []
    @State private var welfareTags: [String] = []
    @State private var companyURL: String = ""
    @State private var myPageURL: String = ""
    @State private var myPageID: String = ""
    @State private var memberNumber: String = ""
    @State private var addresses: [AddressDraft] = []
    @State private var contacts: [ContactDraft] = []
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

    @State private var showingSaveError = false

    private static let industrySuggestions = ["IT・通信", "メーカー", "商社", "金融", "コンサルティング", "広告・マスコミ", "小売・流通", "サービス", "医療・福祉", "官公庁・団体"]
    private static let jobTypeSuggestions = ["総合職", "エンジニア", "営業", "企画・マーケティング", "事務・管理", "研究・開発", "デザイナー", "コンサルタント"]
    private static let welfareSuggestions = ["住宅手当", "リモートワーク可", "フレックスタイム制", "副業可", "退職金制度", "社員食堂", "産休・育休制度", "資格取得支援"]

    private var isSaveDisabled: Bool {
        companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("タブ", selection: $selectedTab) {
                    ForEach(EditCompanyTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 4)

                Group {
                    switch selectedTab {
                    case .basic: basicInfoForm
                    case .flow: selectionFlowForm
                    case .preparation: preparationForm
                    }
                }
            }
            .navigationTitle("企業を編集")
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
            }
            .onAppear(perform: loadExistingData)
        }
    }
    
    private func loadExistingData() {
        companyName = company.companyName
        aspirationLevel = company.aspirationLevel
        overallStatus = company.overallStatus
        industryTags = company.industryTags
        jobTypeTags = company.jobTypeTags
        welfareTags = company.welfareTags
        companyURL = company.companyURL
        myPageURL = company.myPageURL
        myPageID = company.myPageID
        memberNumber = company.memberNumber
        remarks = company.remarks
        
        addresses = company.addresses.map { AddressDraft(label: $0.label, addressText: $0.addressText) }
        if addresses.isEmpty { addresses.append(AddressDraft()) }
        
        contacts = company.contacts.map { ContactDraft(label: $0.label, linkType: $0.linkType, value: $0.value) }
        if contacts.isEmpty { contacts.append(ContactDraft()) }
        
        processDrafts = company.selectionProcesses.sorted(by: { $0.sortOrder < $1.sortOrder }).map {
            ProcessDraft(largeCategory: $0.largeCategory, middleCategory: $0.middleCategory, smallCategory: $0.smallCategory, status: $0.status)
        }
        
        if let note = company.preparationNote {
            selfPR = note.selfPR
            selfPRTargetLength = note.selfPRTargetLength
            gakuchika = note.gakuchika
            gakuchikaTargetLength = note.gakuchikaTargetLength
            motivationReason = note.motivationReason
            motivationTargetLength = note.motivationTargetLength
            preparationRemarks = note.remarks
        }
    }

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
            Section("業界") { TagChipPickerView(placeholder: "業界を追加", suggestedTags: Self.industrySuggestions, selectedTags: $industryTags) }
            Section("職種") { TagChipPickerView(placeholder: "職種を追加", suggestedTags: Self.jobTypeSuggestions, selectedTags: $jobTypeTags) }
            Section("リンク・ID") {
                TextField("企業HP URL", text: $companyURL).keyboardType(.URL).autocorrectionDisabled().textInputAutocapitalization(.never)
                TextField("マイページ URL", text: $myPageURL).keyboardType(.URL).autocorrectionDisabled().textInputAutocapitalization(.never)
                TextField("マイページID", text: $myPageID).autocorrectionDisabled().textInputAutocapitalization(.never)
                TextField("会員番号", text: $memberNumber).autocorrectionDisabled().textInputAutocapitalization(.never)
            }
            Section("住所") { addressCards }
            Section("福利厚生") { TagChipPickerView(placeholder: "福利厚生を追加", suggestedTags: Self.welfareSuggestions, selectedTags: $welfareTags) }
            Section("連絡先") { contactCards }
            Section("備考") { TextEditor(text: $remarks).frame(minHeight: 100) }
        }
    }

    @ViewBuilder private var addressCards: some View {
        ForEach($addresses) { $address in
            VStack(alignment: .leading, spacing: 6) {
                TextField("本社・支店名など", text: $address.label)
                Divider()
                TextField("住所", text: $address.addressText)
            }
            .padding(.vertical, 4)
        }
        .onDelete { addresses.remove(atOffsets: $0) }
        Button { addresses.append(AddressDraft()) } label: { Label("住所を追加", systemImage: "plus.circle") }
    }

    @ViewBuilder private var contactCards: some View {
        ForEach($contacts) { $contact in
            VStack(alignment: .leading, spacing: 6) {
                TextField("担当者名・部署など", text: $contact.label)
                Picker("種別", selection: $contact.linkType) {
                    ForEach(ContactLinkType.allCases) { type in Text(type.rawValue).tag(type) }
                }.pickerStyle(.segmented)
                TextField("電話番号・メールアドレス・URLなど", text: $contact.value).autocorrectionDisabled().textInputAutocapitalization(.never)
            }
            .padding(.vertical, 4)
        }
        .onDelete { contacts.remove(atOffsets: $0) }
        Button { contacts.append(ContactDraft()) } label: { Label("連絡先を追加", systemImage: "plus.circle") }
    }

    private var selectionFlowForm: some View {
        Form {
            Section { Text("面接・テスト・書類提出など、選考プロセスのステップを追加できます。").font(.caption).foregroundStyle(.secondary) }
            ForEach(Array(processDrafts.enumerated()), id: \.element.id) { index, draft in
                Section("プロセス \(index + 1)") {
                    Picker("大分類", selection: processBinding(for: draft.id).largeCategory) {
                        ForEach(LargeCategory.allCases) { category in Text(category.rawValue).tag(category) }
                    }
                    Picker("中分類", selection: processBinding(for: draft.id).middleCategory) {
                        ForEach(MiddleCategory.allCases) { category in Text(category.rawValue).tag(category) }
                    }.onChange(of: draft.middleCategory) { _, newValue in
                        processBinding(for: draft.id).wrappedValue.smallCategory = newValue.defaultSmallCategories.first ?? ""
                    }
                    Picker("小分類", selection: processBinding(for: draft.id).smallCategory) {
                        ForEach(draft.middleCategory.defaultSmallCategories, id: \.self) { small in Text(small).tag(small) }
                    }
                    Picker("ステータス", selection: processBinding(for: draft.id).status) {
                        ForEach(ProcessStatus.allCases) { status in Text(status.rawValue).tag(status) }
                    }
                    Button(role: .destructive) { processDrafts.removeAll { $0.id == draft.id } } label: { Label("このプロセスを削除", systemImage: "trash") }
                }
            }
            Section {
                Button {
                    var newDraft = ProcessDraft()
                    newDraft.smallCategory = newDraft.middleCategory.defaultSmallCategories.first ?? ""
                    processDrafts.append(newDraft)
                } label: { Label("選考プロセスを追加", systemImage: "plus.circle") }
            }
        }
    }

    private var preparationForm: some View {
        Form {
            preparationField(title: "自己PR", text: $selfPR, targetLength: $selfPRTargetLength)
            preparationField(title: "学生時代に力を入れたこと（ガクチカ）", text: $gakuchika, targetLength: $gakuchikaTargetLength)
            preparationField(title: "志望理由", text: $motivationReason, targetLength: $motivationTargetLength)
            Section("その他備考") { TextEditor(text: $preparationRemarks).frame(minHeight: 100) }
        }
    }

    private func preparationField(title: String, text: Binding<String>, targetLength: Binding<Int>) -> some View {
        Section(title) {
            TextEditor(text: text).frame(minHeight: 120)
            HStack {
                Text("\(text.wrappedValue.count)文字").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Stepper("目標: \(targetLength.wrappedValue == 0 ? "未設定" : "\(targetLength.wrappedValue)文字")", value: targetLength, in: 0...2000, step: 50).font(.caption)
            }
        }
    }

    private func processBinding(for id: UUID) -> Binding<ProcessDraft> {
        guard let index = processDrafts.firstIndex(where: { $0.id == id }) else { return .constant(ProcessDraft()) }
        return $processDrafts[index]
    }

    private func save() {
        company.companyName = companyName.trimmingCharacters(in: .whitespacesAndNewlines)
        company.industryTags = industryTags
        company.jobTypeTags = jobTypeTags
        company.aspirationLevel = aspirationLevel
        company.companyURL = companyURL
        company.myPageURL = myPageURL
        company.myPageID = myPageID
        company.memberNumber = memberNumber
        company.welfareTags = welfareTags
        company.remarks = remarks
        company.overallStatus = overallStatus
        company.updatedAt = Date()

        // 関連データの上書き処理 (削除 -> 追加)
        company.addresses.forEach { modelContext.delete($0) }
        for draft in addresses where !draft.addressText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let address = Address(label: draft.label.isEmpty ? "住所" : draft.label, addressText: draft.addressText)
            modelContext.insert(address)
            address.company = company
        }

        company.contacts.forEach { modelContext.delete($0) }
        for draft in contacts where !draft.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let contact = ContactInfo(label: draft.label, linkType: draft.linkType, value: draft.value)
            modelContext.insert(contact)
            contact.company = company
        }

        company.selectionProcesses.forEach { modelContext.delete($0) }
        for (index, draft) in processDrafts.enumerated() {
            let process = SelectionProcess(largeCategory: draft.largeCategory, middleCategory: draft.middleCategory, smallCategory: draft.smallCategory, status: draft.status, sequenceNumber: index + 1, sortOrder: index)
            modelContext.insert(process)
            process.company = company
        }

        if let oldNote = company.preparationNote { modelContext.delete(oldNote) }
        if !selfPR.isEmpty || !gakuchika.isEmpty || !motivationReason.isEmpty || !preparationRemarks.isEmpty {
            let note = SelectionPreparationNote(selfPR: selfPR, selfPRTargetLength: selfPRTargetLength, gakuchika: gakuchika, gakuchikaTargetLength: gakuchikaTargetLength, motivationReason: motivationReason, motivationTargetLength: motivationTargetLength, remarks: preparationRemarks)
            modelContext.insert(note)
            note.company = company
            company.preparationNote = note
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
