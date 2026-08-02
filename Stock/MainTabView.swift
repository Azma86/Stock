//
//  MainTabView.swift
//  Stock
//
//  Created by Mitsuki Kimura on 2026/08/01.
//

//
//  MainTabView.swift
//  就勝Stock
//
//  アプリ全体のタブナビゲーションの土台。
//  requirements.md の「◎カレンダー・スケジュール管理機能」「◎企業プロファイル」
//  「◎就活お役立ち機能」「◎設定」を4タブとして構成する。
//
//  初期表示タブ：カレンダー
//

import SwiftUI
import SwiftData

// MARK: - タブ定義

enum AppTab: Int, CaseIterable, Identifiable {
    case calendar
    case companies
    case tigerScroll
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .calendar:    return "カレンダー"
        case .companies:   return "企業一覧"
        case .tigerScroll: return "虎の巻"
        case .settings:    return "設定"
        }
    }

    var systemImage: String {
        switch self {
        case .calendar:    return "calendar"
        case .companies:   return "building.2"
        case .tigerScroll: return "book"
        case .settings:    return "gearshape"
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    // 初期表示タブは「カレンダー」
    @State private var selectedTab: AppTab = .calendar

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tabContent(for: tab)
                    .tabItem {
                        Label(tab.title, systemImage: tab.systemImage)
                    }
                    .tag(tab)
            }
        }
    }

    @ViewBuilder
    private func tabContent(for tab: AppTab) -> some View {
        switch tab {
        case .calendar:
            CalendarPlaceholderView()
        case .companies:
            CompanyListView()
        case .tigerScroll:
            TigerScrollPlaceholderView()
        case .settings:
            SettingsPlaceholderView()
        }
    }
}

// MARK: - カレンダー（仮UI）
//
// requirements.md「◎カレンダー・スケジュール管理機能」に対応する本実装は別途作成予定。
// ここでは土台として画面遷移のみ確認できる仮UIを配置する。

struct CalendarPlaceholderView: View {
    var body: some View {
        NavigationStack {
            PlaceholderContentView(
                systemImage: "calendar",
                title: "カレンダー",
                message: "選考スケジュールや予定を月表示・日表示で確認できる画面を準備中です。"
            )
            .navigationTitle("カレンダー")
        }
    }
}

// MARK: - 虎の巻（仮UI）
//
// requirements.md「◎就活お役立ち機能」〇虎の巻(豆知識)機能 に対応する本実装は別途作成予定。

struct TigerScrollPlaceholderView: View {
    var body: some View {
        NavigationStack {
            PlaceholderContentView(
                systemImage: "book",
                title: "就活虎の巻",
                message: "就活に関する豆知識をコラム形式で読める画面を準備中です。"
            )
            .navigationTitle("就活虎の巻")
        }
    }
}

// MARK: - 設定（仮UI）
//
// requirements.md「◎設定」に対応する本実装は別途作成予定。

struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            PlaceholderContentView(
                systemImage: "gearshape",
                title: "設定",
                message: "テーマ切替・通知設定・プレミアム機能などを管理する画面を準備中です。"
            )
            .navigationTitle("設定")
        }
    }
}

// MARK: - 共通の仮UIコンポーネント

private struct PlaceholderContentView: View {
    let systemImage: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 56))
                .foregroundStyle(.secondary)

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            overallStatus: .inProgress
        )
        context.insert(sample)
        try? context.save()

        return container
    }()

    return MainTabView()
        .modelContainer(container)
}
