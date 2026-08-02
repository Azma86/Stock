//
//  ContentView.swift
//  Stock
//
//  Created by Mitsuki Kimura on 2026/08/01.
//

//
//  ContentView.swift
//  就勝Stock
//
//  アプリのルートビュー。
//  MainTabView.swift で定義した4タブ構成（カレンダー／企業一覧／虎の巻／設定）を表示する。
//
//  App本体（@main）からは以下のように呼び出す想定:
//
//  @main
//  struct JobHuntApp: App {
//      var body: some Scene {
//          WindowGroup {
//              ContentView()
//          }
//          .modelContainer(for: JobHuntSchema.allModels)
//      }
//  }
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        MainTabView()
    }
}

// MARK: - Preview

#Preview {
    let container: ModelContainer = {
        let schema = Schema(JobHuntSchema.allModels)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])

        let context = container.mainContext

        let sampleCompanies: [CompanyProfile] = [
            CompanyProfile(
                companyName: "株式会社サンプル商事",
                industryTags: ["商社"],
                jobTypeTags: ["総合職"],
                aspirationLevel: .star,
                companyURL: "https://example.com",
                myPageID: "sample_id_001",
                welfareTags: ["住宅手当"],
                overallStatus: .inProgress
            ),
            CompanyProfile(
                companyName: "サンプルIT株式会社",
                industryTags: ["IT"],
                jobTypeTags: ["エンジニア"],
                aspirationLevel: .doubleCircle,
                overallStatus: .considering
            )
        ]

        for company in sampleCompanies {
            context.insert(company)
        }

        try? context.save()
        return container
    }()

    return ContentView()
        .modelContainer(container)
}
