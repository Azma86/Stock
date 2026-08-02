//
//  CompanyDetailView.swift
//  Stock
//
//  Created by Mitsuki Kimura on 2026/08/02.
//

import SwiftUI
import SwiftData

struct CompanyDetailView: View {
    @Bindable var company: CompanyProfile
    @State private var selectedTab = 0

    var body: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("基本情報").tag(0)
                Text("選考フロー").tag(1)
                Text("選考対策").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            List {
                if selectedTab == 0 {
                    basicInfoTab
                } else if selectedTab == 1 {
                    flowTab
                } else {
                    preparationTab
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle(company.companyName)
        .navigationBarTitleDisplayMode(.inline)
    }

    // --- 基本情報タブ ---
    private var basicInfoTab: some View {
        Group {
            detailRow(title: "業界", tags: company.industryTags)
            detailRow(title: "職種", tags: company.jobTypeTags)
            detailTextRow(title: "企業HP", text: company.companyURL)
            detailTextRow(title: "マイページURL", text: company.myPageURL)
            detailTextRow(title: "マイページID", text: company.myPageID)
            detailTextRow(title: "会員番号", text: company.memberNumber)
            detailRow(title: "福利厚生", tags: company.welfareTags)

            Section("住所") {
                if company.addresses.isEmpty {
                    Text("未登録").foregroundStyle(.red)
                } else {
                    ForEach(company.addresses) { address in
                        VStack(alignment: .leading) {
                            Text(address.label).font(.caption).foregroundStyle(.secondary)
                            if address.addressText.isEmpty {
                                Text("未登録").foregroundStyle(.red)
                            } else {
                                Text(address.addressText)
                            }
                        }
                    }
                }
            }

            Section("連絡先") {
                if company.contacts.isEmpty {
                    Text("未登録").foregroundStyle(.red)
                } else {
                    ForEach(company.contacts) { contact in
                        VStack(alignment: .leading) {
                            Text(contact.label).font(.caption).foregroundStyle(.secondary)
                            if contact.value.isEmpty {
                                Text("未登録").foregroundStyle(.red)
                            } else {
                                Text(contact.value)
                            }
                        }
                    }
                }
            }

            Section("備考") {
                detailTextRow(title: "", text: company.remarks, hideTitle: true)
            }
        }
    }

    // --- 選考フロータブ ---
    private var flowTab: some View {
        Group {
            if company.selectionProcesses.isEmpty {
                Text("選考プロセス：未登録").foregroundStyle(.red)
            } else {
                ForEach(company.selectionProcesses.sorted(by: { $0.sortOrder < $1.sortOrder })) { process in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(process.largeCategory.rawValue) > \(process.middleCategory.rawValue)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if process.smallCategory.isEmpty {
                            Text("小分類: 未登録").foregroundStyle(.red).font(.body)
                        } else {
                            Text(process.smallCategory).font(.body)
                        }
                        
                        Text("ステータス: \(process.status.rawValue)")
                            .font(.caption)
                            .foregroundStyle(process.status == .notReached ? .red : .primary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // --- 選考対策タブ ---
    private var preparationTab: some View {
        Group {
            if let note = company.preparationNote {
                detailTextRow(title: "自己PR", text: note.selfPR)
                detailTextRow(title: "ガクチカ", text: note.gakuchika)
                detailTextRow(title: "志望理由", text: note.motivationReason)
                detailTextRow(title: "その他備考", text: note.remarks)
            } else {
                Text("選考対策：未登録").foregroundStyle(.red)
            }
        }
    }

    // --- 共通Rowコンポーネント ---
    @ViewBuilder
    private func detailRow(title: String, tags: [String]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            if tags.isEmpty {
                Text("未登録").foregroundStyle(.red)
            } else {
                Text(tags.joined(separator: ", "))
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func detailTextRow(title: String, text: String, hideTitle: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !hideTitle {
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text("未登録").foregroundStyle(.red)
            } else {
                Text(text)
            }
        }
        .padding(.vertical, 4)
    }
}
