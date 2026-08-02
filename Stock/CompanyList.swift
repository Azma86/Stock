//
//  CompanyListView.swift
//  Stock
//
//  Created by Mitsuki Kimura on 2026/08/01.
//

//
//  CompanyListView.swift
//  就勝Stock
//
//  企業一覧(簡易表示)画面。
//  要件定義を満たすように職種フィルターの追加と、
//  ネイティブアプリらしいカード型レイアウト・チップUIによるデザイン刷新を実施。
//

import SwiftUI
import SwiftData

// MARK: - Color Helpers

private extension ProcessStatus {
    var dotColor: Color {
        switch self {
        case .notReached:    return Color(.systemGray4)
        case .preparing:     return .yellow
        case .waitingResult: return .blue
        case .passed:        return .green
        case .failed:        return .red
        }
    }
}

private extension SelectionOverallStatus {
    var badgeColor: Color {
        switch self {
        case .considering: return .gray
        case .inProgress:  return .blue
        case .offered:     return .green
        case .declined:    return .orange
        case .rejected:    return .red
        }
    }
}

private enum CompanySortOption: String, CaseIterable, Identifiable {
    case aspirationDesc = "志望度が高い順"
    case aspirationAsc = "志望度が低い順"
    case nameAsc = "社名（あいうえお順）"
    case updatedDesc = "更新日が新しい順"

    var id: String { rawValue }
}

// MARK: - CompanyListView

struct CompanyListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \CompanyProfile.companyName, order: .forward)
    private var companies: [CompanyProfile]

    @State private var searchText: String = ""
    @State private var selectedStatuses: Set<SelectionOverallStatus> = []
    @State private var selectedAspirations: Set<AspirationLevel> = []
    
    // 業界・職種のフィルターを明確に分離
    @State private var selectedIndustryTags: Set<String> = []
    @State private var selectedJobTypeTags: Set<String> = []
    @State private var selectedWelfareTags: Set<String> = []
    @State private var sortOption: CompanySortOption = .aspirationDesc

    @State private var showingFilterSheet = false
    @State private var showingAddCompanySheet = false
    @State private var toastMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if filteredAndSortedCompanies.isEmpty {
                    emptyStateView
                } else {
                    // 非機能要件(描画最適化)に沿ってScrollView + LazyVStackを採用
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredAndSortedCompanies) { company in
                                NavigationLink {
                                    Text(company.companyName)
                                        .navigationTitle(company.companyName)
                                } label: {
                                    CompanyCardView(company: company) { message in
                                        showToast(message)
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                    }
                    .background(Color(.systemGroupedBackground))
                }
            }
            .navigationTitle("企業一覧")
            .searchable(text: $searchText, prompt: "社名で検索")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingFilterSheet = true
                    } label: {
                        Image(systemName: isFilterActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("絞り込み・並べ替え")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCompanySheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("新規企業を追加")
                }
            }
            .sheet(isPresented: $showingFilterSheet) {
                CompanyFilterSheet(
                    allCompanies: companies,
                    selectedStatuses: $selectedStatuses,
                    selectedAspirations: $selectedAspirations,
                    selectedIndustryTags: $selectedIndustryTags,
                    selectedJobTypeTags: $selectedJobTypeTags,
                    selectedWelfareTags: $selectedWelfareTags,
                    sortOption: $sortOption
                )
            }
            .sheet(isPresented: $showingAddCompanySheet) {
                AddCompanyView()
            }
            .overlay(alignment: .bottom) {
                if let toastMessage {
                    ToastView(message: toastMessage)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "企業が見つかりません",
            systemImage: "building.2",
            description: Text(isFilterActive || !searchText.isEmpty
                               ? "検索条件・絞り込み条件を変更してください"
                               : "右上の「＋」から企業プロファイルを追加しましょう")
        )
    }

    private var isFilterActive: Bool {
        !selectedStatuses.isEmpty || !selectedAspirations.isEmpty
            || !selectedIndustryTags.isEmpty || !selectedJobTypeTags.isEmpty || !selectedWelfareTags.isEmpty
    }

    private var filteredAndSortedCompanies: [CompanyProfile] {
        var result = companies

        if !searchText.isEmpty {
            result = result.filter {
                $0.companyName.localizedCaseInsensitiveContains(searchText)
            }
        }
        if !selectedStatuses.isEmpty {
            result = result.filter { selectedStatuses.contains($0.overallStatus) }
        }
        if !selectedAspirations.isEmpty {
            result = result.filter { selectedAspirations.contains($0.aspirationLevel) }
        }
        if !selectedIndustryTags.isEmpty {
            result = result.filter { !Set($0.industryTags).isDisjoint(with: selectedIndustryTags) }
        }
        if !selectedJobTypeTags.isEmpty {
            result = result.filter { !Set($0.jobTypeTags).isDisjoint(with: selectedJobTypeTags) }
        }
        if !selectedWelfareTags.isEmpty {
            result = result.filter { !Set($0.welfareTags).isDisjoint(with: selectedWelfareTags) }
        }

        switch sortOption {
        case .aspirationDesc:
            result.sort { $0.aspirationLevel.rawValue > $1.aspirationLevel.rawValue }
        case .aspirationAsc:
            result.sort { $0.aspirationLevel.rawValue < $1.aspirationLevel.rawValue }
        case .nameAsc:
            result.sort { $0.companyName.localizedStandardCompare($1.companyName) == .orderedAscending }
        case .updatedDesc:
            result.sort { $0.updatedAt > $1.updatedAt }
        }

        return result
    }

    private func showToast(_ message: String) {
        withAnimation { toastMessage = message }
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            withAnimation { toastMessage = nil }
        }
    }
}

// MARK: - CompanyCardView（UIを刷新したカード型デザイン）

private struct CompanyCardView: View {
    @Bindable var company: CompanyProfile
    var onCopy: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 上段：社名・タグ・ステータス
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(company.companyName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    let tags = company.industryTags + company.jobTypeTags
                    if !tags.isEmpty {
                        Text(tags.joined(separator: " / "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer(minLength: 12)
                VStack(alignment: .trailing, spacing: 6) {
                    Text(company.overallStatus.rawValue)
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(company.overallStatus.badgeColor.opacity(0.15))
                        .foregroundStyle(company.overallStatus.badgeColor)
                        .clipShape(Capsule())

                    Text(company.aspirationLevel.symbol)
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            }

            // 中段：プログレスバー
            if !company.selectionProcesses.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("選考プロセス")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    SimpleProgressDotsView(processes: company.selectionProcesses)
                }
            }

            Divider()
                .padding(.vertical, 2)

            // 下段：アクションボタン群と通知トグル
            HStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        if !company.companyURL.isEmpty {
                            actionChip(title: "企業HP", icon: "globe", isLink: true) { openURL(company.companyURL) }
                        }
                        if !company.myPageURL.isEmpty {
                            actionChip(title: "マイページ", icon: "person.text.rectangle", isLink: true) { openURL(company.myPageURL) }
                        }
                        if !company.myPageID.isEmpty {
                            actionChip(title: "ID", icon: "doc.on.doc", isLink: false) { copy(company.myPageID, "ID") }
                        }
                        if !company.memberNumber.isEmpty {
                            actionChip(title: "会員番号", icon: "doc.on.doc", isLink: false) { copy(company.memberNumber, "会員番号") }
                        }
                    }
                }
                
                Spacer(minLength: 16)
                
                Toggle("通知", isOn: $company.notificationEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .scaleEffect(0.75)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private func actionChip(title: String, icon: String, isLink: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isLink ? Color.blue.opacity(0.1) : Color(.tertiarySystemFill), in: Capsule())
            .foregroundStyle(isLink ? Color.blue : Color.primary)
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }
        #if canImport(UIKit)
        UIApplication.shared.open(url)
        #endif
    }

    private func copy(_ value: String, _ label: String) {
        #if canImport(UIKit)
        UIPasteboard.general.string = value
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
        onCopy("\(label)をコピーしました")
    }
}

// MARK: - SimpleProgressDotsView

private struct SimpleProgressDotsView: View {
    let processes: [SelectionProcess]
    private var sortedProcesses: [SelectionProcess] {
        processes.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(sortedProcesses.enumerated()), id: \.element.id) { index, process in
                Circle()
                    .fill(process.status.dotColor)
                    .frame(width: 8, height: 8)

                if index < sortedProcesses.count - 1 {
                    Capsule()
                        .fill(Color(.quaternaryLabel))
                        .frame(width: 12, height: 2)
                }
            }
        }
    }
}

// MARK: - ToastView

private struct ToastView: View {
    let message: String
    var body: some View {
        Text(message)
            .font(.subheadline)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.8), in: Capsule())
            .foregroundStyle(.white)
            .shadow(radius: 4)
    }
}

// MARK: - CompanyFilterSheet（絞り込み・並べ替えシート）

private struct CompanyFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    let allCompanies: [CompanyProfile]

    @Binding var selectedStatuses: Set<SelectionOverallStatus>
    @Binding var selectedAspirations: Set<AspirationLevel>
    @Binding var selectedIndustryTags: Set<String>
    @Binding var selectedJobTypeTags: Set<String>
    @Binding var selectedWelfareTags: Set<String>
    @Binding var sortOption: CompanySortOption

    private var allIndustryTags: [String] {
        Set(allCompanies.flatMap { $0.industryTags }).sorted()
    }
    
    private var allJobTypeTags: [String] {
        Set(allCompanies.flatMap { $0.jobTypeTags }).sorted()
    }

    private var allWelfareTags: [String] {
        Set(allCompanies.flatMap { $0.welfareTags }).sorted()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("並べ替え") {
                    Picker("並べ替え", selection: $sortOption) {
                        ForEach(CompanySortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section("選考ステータス") {
                    ForEach(SelectionOverallStatus.allCases) { status in
                        multiSelectRow(title: status.rawValue, isSelected: selectedStatuses.contains(status)) {
                            toggle(status, in: &selectedStatuses)
                        }
                    }
                }

                Section("志望度") {
                    ForEach(AspirationLevel.allCases.sorted(by: { $0.rawValue > $1.rawValue })) { level in
                        multiSelectRow(title: "\(level.symbol)", isSelected: selectedAspirations.contains(level)) {
                            toggle(level, in: &selectedAspirations)
                        }
                    }
                }

                if !allIndustryTags.isEmpty {
                    Section("業界") {
                        ForEach(allIndustryTags, id: \.self) { tag in
                            multiSelectRow(title: tag, isSelected: selectedIndustryTags.contains(tag)) {
                                toggle(tag, in: &selectedIndustryTags)
                            }
                        }
                    }
                }
                
                if !allJobTypeTags.isEmpty {
                    Section("職種") {
                        ForEach(allJobTypeTags, id: \.self) { tag in
                            multiSelectRow(title: tag, isSelected: selectedJobTypeTags.contains(tag)) {
                                toggle(tag, in: &selectedJobTypeTags)
                            }
                        }
                    }
                }

                if !allWelfareTags.isEmpty {
                    Section("福利厚生") {
                        ForEach(allWelfareTags, id: \.self) { tag in
                            multiSelectRow(title: tag, isSelected: selectedWelfareTags.contains(tag)) {
                                toggle(tag, in: &selectedWelfareTags)
                            }
                        }
                    }
                }
            }
            .navigationTitle("絞り込み・並べ替え")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("リセット") {
                        selectedStatuses.removeAll()
                        selectedAspirations.removeAll()
                        selectedIndustryTags.removeAll()
                        selectedJobTypeTags.removeAll()
                        selectedWelfareTags.removeAll()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func multiSelectRow(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.blue)
                }
            }
        }
    }

    private func toggle<T: Hashable>(_ value: T, in set: inout Set<T>) {
        if set.contains(value) {
            set.remove(value)
        } else {
            set.insert(value)
        }
    }
}

// MARK: - Preview
#Preview {
    let container: ModelContainer = {
        let schema = Schema(JobHuntSchema.allModels)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        let context = container.mainContext
        
        let sample = CompanyProfile(
            companyName: "株式会社サンプル商事",
            industryTags: ["商社"],
            jobTypeTags: ["総合職"],
            aspirationLevel: .star,
            companyURL: "https://example.com",
            myPageURL: "https://mypage.example.com",
            myPageID: "sample_id_001",
            memberNumber: "M-0001",
            welfareTags: ["住宅手当"],
            overallStatus: .inProgress
        )
        context.insert(sample)
        
        let process = SelectionProcess(middleCategory: .interview, smallCategory: "個人面接", status: .passed, sortOrder: 0)
        process.company = sample
        context.insert(process)
        
        try? context.save()
        return container
    }()

    return CompanyListView()
        .modelContainer(container)
}
