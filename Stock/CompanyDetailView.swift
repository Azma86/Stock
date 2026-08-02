//
//  CompanyDetailView.swift
//  Stock
//
//  Created by Mitsuki Kimura on 2026/08/01.
//

import SwiftUI
import SwiftData

private enum DetailTab: String, CaseIterable, Identifiable {
    case basic = "基本情報"
    case flow = "選考フロー"
    case preparation = "選考対策"

    var id: String { rawValue }
}

struct CompanyDetailView: View {
    @Bindable var company: CompanyProfile
    @State private var selectedTab: DetailTab = .basic
    @State private var showingEditSheet = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("タブ", selection: $selectedTab) {
                ForEach(DetailTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))

            ScrollView {
                VStack(spacing: 16) {
                    switch selectedTab {
                    case .basic:
                        BasicInfoDetailView(company: company)
                    case .flow:
                        SelectionFlowDetailView(processes: company.selectionProcesses)
                    case .preparation:
                        PreparationDetailView(note: company.preparationNote)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
        }
        .navigationTitle(company.companyName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("編集") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditCompanyView(company: company)
        }
    }
}

// MARK: - 基本情報タブ
private struct BasicInfoDetailView: View {
    let company: CompanyProfile

    var body: some View {
        VStack(spacing: 16) {
            DetailCard {
                DetailRow(title: "選考ステータス", value: company.overallStatus.rawValue)
                Divider()
                DetailRow(title: "志望度", value: company.aspirationLevel.symbol)
            }

            if !company.industryTags.isEmpty || !company.jobTypeTags.isEmpty || !company.welfareTags.isEmpty {
                DetailCard {
                    if !company.industryTags.isEmpty {
                        TagListRow(title: "業界", tags: company.industryTags)
                    }
                    if !company.jobTypeTags.isEmpty {
                        if !company.industryTags.isEmpty { Divider() }
                        TagListRow(title: "職種", tags: company.jobTypeTags)
                    }
                    if !company.welfareTags.isEmpty {
                        if !company.industryTags.isEmpty || !company.jobTypeTags.isEmpty { Divider() }
                        TagListRow(title: "福利厚生", tags: company.welfareTags)
                    }
                }
            }

            if !company.addresses.isEmpty {
                DetailCard(title: "住所") {
                    ForEach(company.addresses) { address in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(address.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(address.addressText)
                                .font(.body)
                        }
                        if address != company.addresses.last {
                            Divider()
                        }
                    }
                }
            }

            if !company.contacts.isEmpty {
                DetailCard(title: "連絡先") {
                    ForEach(company.contacts) { contact in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(contact.label) (\(contact.linkType.rawValue))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(contact.value)
                                .font(.body)
                        }
                        if contact != company.contacts.last {
                            Divider()
                        }
                    }
                }
            }
            
            if !company.remarks.isEmpty {
                DetailCard(title: "備考") {
                    Text(company.remarks)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

// MARK: - 選考フロータブ
private extension ProcessStatus {
    var dotColor: Color {
        switch self {
        case .notReached: return Color(.systemGray4)
        case .preparing: return .yellow
        case .waitingResult: return .blue
        case .passed: return .green
        case .failed: return .red
        }
    }
}

private struct SelectionFlowDetailView: View {
    let processes: [SelectionProcess]

    var body: some View {
        DetailCard {
            if processes.isEmpty {
                Text("選考プロセスが登録されていません。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                let sorted = processes.sorted(by: { $0.sortOrder < $1.sortOrder })
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(sorted.enumerated()), id: \.element.id) { index, process in
                        HStack(alignment: .top, spacing: 16) {
                            VStack(spacing: 0) {
                                Circle()
                                    .fill(process.status.dotColor)
                                    .frame(width: 14, height: 14)
                                    .padding(.top, 4)
                                
                                if index != sorted.count - 1 {
                                    Rectangle()
                                        .fill(Color(.systemGray5))
                                        .frame(width: 2)
                                        .padding(.vertical, 4)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(process.smallCategory)
                                    .font(.headline)
                                Text("\(process.largeCategory.rawValue) / \(process.middleCategory.rawValue)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(process.status.rawValue)
                                    .font(.caption.bold())
                                    .foregroundStyle(process.status.dotColor)
                            }
                            .padding(.bottom, 24)
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

// MARK: - 選考対策タブ
private struct PreparationDetailView: View {
    let note: SelectionPreparationNote?

    var body: some View {
        VStack(spacing: 16) {
            if let note = note {
                if !note.selfPR.isEmpty {
                    DetailCard(title: "自己PR") {
                        Text(note.selfPR)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if !note.gakuchika.isEmpty {
                    DetailCard(title: "ガクチカ") {
                        Text(note.gakuchika)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if !note.motivationReason.isEmpty {
                    DetailCard(title: "志望理由") {
                        Text(note.motivationReason)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                if !note.remarks.isEmpty {
                    DetailCard(title: "その他備考") {
                        Text(note.remarks)
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                DetailCard {
                    Text("選考対策情報が登録されていません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 16)
                }
            }
        }
    }
}

// MARK: - UI Components
private struct DetailCard<Content: View>: View {
    var title: String? = nil
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title = title {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

private struct DetailRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(.primary)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
        .font(.body)
    }
}

private struct TagListRow: View {
    let title: String
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            FlowLayout(spacing: 6) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }
        }
    }
}
