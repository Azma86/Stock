//
//  Job HuntDataModels.swift
//  Stock
//
//  Created by Mitsuki Kimura on 2026/08/01.
//

//
//  JobHuntDataModels.swift
//  就活管理アプリ - SwiftData モデル定義
//
//  要件定義書(requirements.md)を元に生成。
//  対象: iOS 17+ / SwiftData
//
//  注意:
//  - 会員登録・ログインなし、完全ローカル保存前提のためリレーションはUUID主体。
//  - 画像データは @Attribute(.externalStorage) を必ず指定し、DB肥大化を防止。
//  - 親削除時は @Relationship(deleteRule: .cascade) で子データを自動削除。
//  - Enum系プロパティはSwiftDataの制約上 String/Int の raw 値で保持し、
//    computed property でアプリ側から Enum として安全に扱えるようにしている。
//

import Foundation
import SwiftData

// MARK: - Enums

/// 志望度（★, ◎, 〇, △の4段階。内部では数値で保持）
enum AspirationLevel: Int, Codable, CaseIterable, Identifiable {
    case star = 4          // ★
    case doubleCircle = 3  // ◎
    case circle = 2        // 〇
    case triangle = 1      // △

    var id: Int { rawValue }

    var symbol: String {
        switch self {
        case .star: return "★"
        case .doubleCircle: return "◎"
        case .circle: return "〇"
        case .triangle: return "△"
        }
    }
}

/// 企業一覧・企業プロファイルの選考ステータス
enum SelectionOverallStatus: String, Codable, CaseIterable, Identifiable {
    case considering = "検討中"
    case inProgress = "選考中"
    case offered = "内定"
    case declined = "辞退"
    case rejected = "不合格"

    var id: String { rawValue }
}

/// 選考プロセス 大分類
enum LargeCategory: String, Codable, CaseIterable, Identifiable {
    case internship = "インターン"
    case mainSelection = "本選考"
    case other = "その他"

    var id: String { rawValue }
}

/// 選考プロセス 中分類
enum MiddleCategory: String, Codable, CaseIterable, Identifiable {
    case interview = "面接"
    case meetingBriefing = "面談・説明会"
    case test = "テスト"
    case documentSubmission = "書類提出"
    case offerAcceptance = "内定・承諾"

    var id: String { rawValue }

    /// カレンダー・プログレスバーの色分けに使用するカラーアセット名
    var colorAssetName: String {
        switch self {
        case .interview: return "categoryInterview"
        case .meetingBriefing: return "categoryMeeting"
        case .test: return "categoryTest"
        case .documentSubmission: return "categoryDocument"
        case .offerAcceptance: return "categoryOffer"
        }
    }

    /// 小分類の初期候補（ユーザーは「その他」から自作項目を追加可能）
    var defaultSmallCategories: [String] {
        switch self {
        case .interview:
            return ["動画提出", "電話面接", "役員面接", "集団・グループ(対面)",
                    "集団・グループ(オンライン)", "個人面接(対面)", "個人面接(オンライン)", "その他"]
        case .meetingBriefing:
            return ["カジュアル面談", "リクルーター面談", "GD(グループディスカッション)",
                    "グループワーク", "会社説明会、セミナー", "選考会", "その他"]
        case .test:
            return ["Webテスト", "筆記試験", "コーディング・実技試験", "性格検査・適性検査",
                    "SPI", "玉手箱", "企業独自テスト", "その他"]
        case .documentSubmission:
            return ["ES(エントリーシート)", "履歴書", "研究概要書", "ポートフォリオ",
                    "課題・小論文", "アンケート回答", "成績証明書・卒業見込証明書", "その他"]
        case .offerAcceptance:
            return ["内定・内々定通知", "オファー面談、条件提示面談", "内定式", "内定承諾書提出", "その他"]
        }
    }
}

/// 選考プロセスの進捗ステータス（プログレスバーのドットの色に対応）
enum ProcessStatus: String, Codable, CaseIterable, Identifiable {
    case notReached = "未到達"      // 灰
    case preparing = "準備中"       // 黄（書類提出タブでは「作成中」としてUI表示してもよい）
    case waitingResult = "結果待ち"  // 青
    case passed = "通過済み"        // 緑
    case failed = "辞退・不合格"     // 赤

    var id: String { rawValue }

    var colorAssetName: String {
        switch self {
        case .notReached: return "statusGray"
        case .preparing: return "statusYellow"
        case .waitingResult: return "statusBlue"
        case .passed: return "statusGreen"
        case .failed: return "statusRed"
        }
    }
}

/// 予定の場所種別
enum LocationType: String, Codable, CaseIterable, Identifiable {
    case registeredAddress = "登録済み住所"
    case onlineZoom = "オンライン(Zoom)"
    case onlineGoogleMeet = "オンライン(Google Meet)"
    case onlineOther = "オンライン(その他)"
    case other = "その他"

    var id: String { rawValue }
}

/// 連絡先の種別（タップ時の挙動分岐に使用）
enum ContactLinkType: String, Codable, CaseIterable, Identifiable {
    case phone = "電話"
    case email = "メール"
    case slack = "Slack"
    case other = "その他リンク"

    var id: String { rawValue }
}

// MARK: - CompanyProfile（企業プロファイル）

@Model
final class CompanyProfile {
    var id: UUID = UUID()

    /// 社名（必須項目）
    var companyName: String = ""

    /// 業界タグ（チップ形式、自作項目追加可）
    var industryTags: [String] = []

    /// 職種タグ（チップ形式、自作項目追加可）
    var jobTypeTags: [String] = []

    /// 志望度（内部ではInt rawValueで保持）
    var aspirationLevelRaw: Int = AspirationLevel.circle.rawValue

    var companyURL: String = ""
    var myPageURL: String = ""
    var myPageID: String = ""
    var memberNumber: String = ""

    /// 福利厚生タグ（チップ形式、自作項目追加可）
    var welfareTags: [String] = []

    var remarks: String = ""

    /// 通知設定のオンオフ（簡易表示用）
    var notificationEnabled: Bool = true

    /// 選考ステータス（検討中、選考中、内定、辞退、不合格）
    var overallStatusRaw: String = SelectionOverallStatus.considering.rawValue

    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    // MARK: Relationships（親削除で子も自動削除）

    @Relationship(deleteRule: .cascade, inverse: \Address.company)
    var addresses: [Address] = []

    @Relationship(deleteRule: .cascade, inverse: \ContactInfo.company)
    var contacts: [ContactInfo] = []

    @Relationship(deleteRule: .cascade, inverse: \AttachedImage.company)
    var images: [AttachedImage] = []

    @Relationship(deleteRule: .cascade, inverse: \SelectionProcess.company)
    var selectionProcesses: [SelectionProcess] = []

    @Relationship(deleteRule: .cascade, inverse: \Schedule.company)
    var schedules: [Schedule] = []

    @Relationship(deleteRule: .cascade, inverse: \QuestionCompanyAnswer.company)
    var questionAnswers: [QuestionCompanyAnswer] = []

    /// 選考対策タブ（自己PR・ガクチカ・志望理由など）は1企業につき1件
    @Relationship(deleteRule: .cascade)
    var preparationNote: SelectionPreparationNote?

    // MARK: Computed Enum Accessors

    var aspirationLevel: AspirationLevel {
        get { AspirationLevel(rawValue: aspirationLevelRaw) ?? .circle }
        set { aspirationLevelRaw = newValue.rawValue }
    }

    var overallStatus: SelectionOverallStatus {
        get { SelectionOverallStatus(rawValue: overallStatusRaw) ?? .considering }
        set { overallStatusRaw = newValue.rawValue }
    }

    init(
        companyName: String,
        industryTags: [String] = [],
        jobTypeTags: [String] = [],
        aspirationLevel: AspirationLevel = .circle,
        companyURL: String = "",
        myPageURL: String = "",
        myPageID: String = "",
        memberNumber: String = "",
        welfareTags: [String] = [],
        remarks: String = "",
        notificationEnabled: Bool = true,
        overallStatus: SelectionOverallStatus = .considering
    ) {
        self.id = UUID()
        self.companyName = companyName
        self.industryTags = industryTags
        self.jobTypeTags = jobTypeTags
        self.aspirationLevelRaw = aspirationLevel.rawValue
        self.companyURL = companyURL
        self.myPageURL = myPageURL
        self.myPageID = myPageID
        self.memberNumber = memberNumber
        self.welfareTags = welfareTags
        self.remarks = remarks
        self.notificationEnabled = notificationEnabled
        self.overallStatusRaw = overallStatus.rawValue
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

// MARK: - Address（住所：本社・支店など複数登録可）

@Model
final class Address {
    var id: UUID = UUID()

    /// 本社、支店名など
    var label: String = "本社"
    var postalCode: String = ""
    var addressText: String = ""

    /// マップアプリ起動用（任意）
    var latitude: Double?
    var longitude: Double?

    var company: CompanyProfile?

    init(
        label: String = "本社",
        postalCode: String = "",
        addressText: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = UUID()
        self.label = label
        self.postalCode = postalCode
        self.addressText = addressText
        self.latitude = latitude
        self.longitude = longitude
    }
}

// MARK: - ContactInfo（連絡先：複数登録可）

@Model
final class ContactInfo {
    var id: UUID = UUID()

    /// 担当者名・部署名など
    var label: String = ""
    var linkTypeRaw: String = ContactLinkType.phone.rawValue

    /// 電話番号 / メールアドレス / SlackリンクURL 等
    var value: String = ""

    var company: CompanyProfile?

    var linkType: ContactLinkType {
        get { ContactLinkType(rawValue: linkTypeRaw) ?? .phone }
        set { linkTypeRaw = newValue.rawValue }
    }

    init(label: String = "", linkType: ContactLinkType = .phone, value: String = "") {
        self.id = UUID()
        self.label = label
        self.linkTypeRaw = linkType.rawValue
        self.value = value
    }
}

// MARK: - AttachedImage（添付画像：無料1枚/プレミアム10枚まで ※上限判定はUI/ロジック側で実施）

@Model
final class AttachedImage {
    var id: UUID = UUID()

    /// 画像本体。DB肥大化防止のため必ず外部ストレージに保存する。
    /// 保存前に自動リサイズ・圧縮（JPEG品質80%等）を行った上でセットすること。
    @Attribute(.externalStorage)
    var imageData: Data = Data()

    var caption: String = ""
    var createdAt: Date = Date()

    var company: CompanyProfile?

    init(imageData: Data, caption: String = "") {
        self.id = UUID()
        self.imageData = imageData
        self.caption = caption
        self.createdAt = Date()
    }
}

// MARK: - SelectionProcess（選考フロー：大中小分類で管理する進捗ステップ）

@Model
final class SelectionProcess {
    var id: UUID = UUID()

    var largeCategoryRaw: String = LargeCategory.mainSelection.rawValue
    var middleCategoryRaw: String = MiddleCategory.interview.rawValue

    /// 小分類（初期候補はMiddleCategory.defaultSmallCategoriesから選択、自由入力も可）
    var smallCategory: String = ""

    var statusRaw: String = ProcessStatus.notReached.rawValue

    /// 1次、2次、最終等の自動カウント用（同一middleCategory内での連番）
    var sequenceNumber: Int = 1

    /// プログレスバー上の表示順
    var sortOrder: Int = 0

    var createdAt: Date = Date()

    // --- 事前メモ（種類により使用する項目が異なる。未使用項目は空文字のまま） ---
    var appealPoints: String = ""        // 面接：アピールしたいこと
    var counterQuestions: String = ""    // 面接：逆質問
    var expectedQAMemo: String = ""      // 面接：想定質問と回答メモ
    var questionMemo: String = ""        // 面談・説明会：確認しておきたいこと（質問メモ）
    var precautionMemo: String = ""      // テスト：注意事項メモ（電卓可否・傾向等）
    var essayQAMemo: String = ""         // 書類提出：設問と回答メモ
    var laborConditions: String = ""     // 内定・承諾：労働条件など
    var preRemarks: String = ""          // 事前その他備考（共通）

    // --- 事後メモ ---
    var impression: String = ""          // 手ごたえ（面接・テスト共通）
    var actualQARecord: String = ""      // 面接：実際に聞かれたことと回答記録
    var improvementPoints: String = ""   // 改善点（面接・テスト・書類共通）
    var learnings: String = ""           // 面談・説明会：分かったこと
    var futureActions: String = ""       // 面談・説明会：今後に向けて
    var difficulty: String = ""          // テスト：難易度
    var problemRecord: String = ""       // テスト：問題と回答記録
    var decisionReasonMemo: String = ""  // 内定・承諾：承諾・辞退と理由メモ
    var postRemarks: String = ""         // 事後その他備考（共通）

    /// 面談・説明会：選考要素があるか
    var hasSelectionElement: Bool = false
    /// 書類提出：提出方法
    var submissionMethod: String = ""

    var company: CompanyProfile?

    /// このプロセスに紐づく予定（予定作成画面から自動登録される）
    @Relationship(deleteRule: .cascade, inverse: \Schedule.selectionProcess)
    var schedules: [Schedule] = []

    // MARK: Computed Enum Accessors

    var largeCategory: LargeCategory {
        get { LargeCategory(rawValue: largeCategoryRaw) ?? .mainSelection }
        set { largeCategoryRaw = newValue.rawValue }
    }

    var middleCategory: MiddleCategory {
        get { MiddleCategory(rawValue: middleCategoryRaw) ?? .interview }
        set { middleCategoryRaw = newValue.rawValue }
    }

    var status: ProcessStatus {
        get { ProcessStatus(rawValue: statusRaw) ?? .notReached }
        set { statusRaw = newValue.rawValue }
    }

    init(
        largeCategory: LargeCategory = .mainSelection,
        middleCategory: MiddleCategory = .interview,
        smallCategory: String = "",
        status: ProcessStatus = .notReached,
        sequenceNumber: Int = 1,
        sortOrder: Int = 0
    ) {
        self.id = UUID()
        self.largeCategoryRaw = largeCategory.rawValue
        self.middleCategoryRaw = middleCategory.rawValue
        self.smallCategory = smallCategory
        self.statusRaw = status.rawValue
        self.sequenceNumber = sequenceNumber
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}

// MARK: - Schedule（カレンダー予定：企業・選考プロセスと連携）

@Model
final class Schedule {
    var id: UUID = UUID()

    var title: String = ""
    var startDate: Date = Date()
    var endDate: Date = Date()

    var locationTypeRaw: String = LocationType.other.rawValue
    /// 場所の詳細住所、またはオンラインURL等
    var locationDetail: String = ""

    /// 予定日の◯日前リマインド設定
    var reminderDaysBefore: Int = 1

    /// 提出締め切りかどうか（当日に確認ダイアログを出す対象）
    var isDeadline: Bool = false
    /// 提出締め切り当日の確認結果
    var isSubmissionConfirmed: Bool = false

    var notes: String = ""
    var createdAt: Date = Date()

    var company: CompanyProfile?
    var selectionProcess: SelectionProcess?

    var locationType: LocationType {
        get { LocationType(rawValue: locationTypeRaw) ?? .other }
        set { locationTypeRaw = newValue.rawValue }
    }

    init(
        title: String,
        startDate: Date = Date(),
        endDate: Date = Date(),
        locationType: LocationType = .other,
        locationDetail: String = "",
        reminderDaysBefore: Int = 1,
        isDeadline: Bool = false,
        notes: String = ""
    ) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.locationTypeRaw = locationType.rawValue
        self.locationDetail = locationDetail
        self.reminderDaysBefore = reminderDaysBefore
        self.isDeadline = isDeadline
        self.isSubmissionConfirmed = false
        self.notes = notes
        self.createdAt = Date()
    }
}

// MARK: - EffortLog（がんばったこと記録：ガクチカ用、企業に紐付かないカレンダー記録）

@Model
final class EffortLog {
    var id: UUID = UUID()
    var date: Date = Date()
    var content: String = ""
    var createdAt: Date = Date()

    init(date: Date = Date(), content: String = "") {
        self.id = UUID()
        self.date = date
        self.content = content
        self.createdAt = Date()
    }
}

// MARK: - SelectionPreparationNote（選考対策タブ：長文入力欄、企業ごとに1件）

@Model
final class SelectionPreparationNote {
    var id: UUID = UUID()

    var selfPR: String = ""
    /// 目標文字数（0の場合は未設定として扱う）
    var selfPRTargetLength: Int = 0

    var gakuchika: String = ""
    var gakuchikaTargetLength: Int = 0

    var motivationReason: String = ""
    var motivationTargetLength: Int = 0

    var remarks: String = ""
    var updatedAt: Date = Date()

    var company: CompanyProfile?

    init(
        selfPR: String = "",
        selfPRTargetLength: Int = 0,
        gakuchika: String = "",
        gakuchikaTargetLength: Int = 0,
        motivationReason: String = "",
        motivationTargetLength: Int = 0,
        remarks: String = ""
    ) {
        self.id = UUID()
        self.selfPR = selfPR
        self.selfPRTargetLength = selfPRTargetLength
        self.gakuchika = gakuchika
        self.gakuchikaTargetLength = gakuchikaTargetLength
        self.motivationReason = motivationReason
        self.motivationTargetLength = motivationTargetLength
        self.remarks = remarks
        self.updatedAt = Date()
    }
}

// MARK: - QuestionStockItem（質問ストック：共通の質問＋共通回答）

@Model
final class QuestionStockItem {
    var id: UUID = UUID()
    var questionText: String = ""

    /// 共通の回答メモ（企業を問わず使う想定の回答）
    var commonAnswer: String = ""

    /// 初期データ（定型質問：自己PR、ガクチカ、長所短所等）かどうか
    var isDefault: Bool = false

    var createdAt: Date = Date()

    /// 企業ごとの個別回答メモ
    @Relationship(deleteRule: .cascade, inverse: \QuestionCompanyAnswer.question)
    var companyAnswers: [QuestionCompanyAnswer] = []

    init(questionText: String, commonAnswer: String = "", isDefault: Bool = false) {
        self.id = UUID()
        self.questionText = questionText
        self.commonAnswer = commonAnswer
        self.isDefault = isDefault
        self.createdAt = Date()
    }
}

// MARK: - QuestionCompanyAnswer（質問ストックの企業別回答メモ）

@Model
final class QuestionCompanyAnswer {
    var id: UUID = UUID()
    var answerText: String = ""
    var updatedAt: Date = Date()

    var question: QuestionStockItem?
    var company: CompanyProfile?

    init(answerText: String = "") {
        self.id = UUID()
        self.answerText = answerText
        self.updatedAt = Date()
    }
}

// MARK: - Schema / ModelContainer セットアップ

enum JobHuntSchema {
    /// ModelContainer初期化時に渡す全モデル一覧
    static let allModels: [any PersistentModel.Type] = [
        CompanyProfile.self,
        Address.self,
        ContactInfo.self,
        AttachedImage.self,
        SelectionProcess.self,
        Schedule.self,
        EffortLog.self,
        SelectionPreparationNote.self,
        QuestionStockItem.self,
        QuestionCompanyAnswer.self
    ]

    /// App本体で使用する ModelContainer を生成するヘルパー
    /// 使用例:
    ///   let container = try JobHuntSchema.makeContainer()
    ///   ContentView().modelContainer(container)
    static func makeContainer(inMemoryOnly: Bool = false) throws -> ModelContainer {
        let schema = Schema(allModels)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: inMemoryOnly)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    /// 初回起動時にサンプルの定型質問をシードするヘルパー
    /// 使用例: JobHuntSchema.seedDefaultQuestions(into: modelContext)
    @MainActor
    static func seedDefaultQuestions(into context: ModelContext) {
        let defaults: [(String, String)] = [
            ("自己PRをしてください", ""),
            ("学生時代に力を入れたことは何ですか（ガクチカ）", ""),
            ("あなたの長所と短所を教えてください", ""),
            ("なぜ弊社を志望したのですか", ""),
            ("入社後にやりたいことは何ですか", "")
        ]

        // 既に定型質問が登録済みの場合は重複登録しない
        let descriptor = FetchDescriptor<QuestionStockItem>(
            predicate: #Predicate { $0.isDefault == true }
        )
        let existingCount = (try? context.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        for (question, answer) in defaults {
            let item = QuestionStockItem(questionText: question, commonAnswer: answer, isDefault: true)
            context.insert(item)
        }
    }
}
