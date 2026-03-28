## 最重要ルール（絶対遵守）

* Phase 1 設計合意後に Issue + 作業ブランチを作成してから実装開始（GitHub Project「Hobby Matching」）
* RED → GREEN → REFACTOR → PR
* すべてのコマンドは `docker compose exec web` 経由
* PR前に RSpec / RuboCop 全通過
* 不明点は必ず質問する（推測で実装しない）
* 仕様に曖昧さがある場合、実装せず Phase 0 に戻る

---

# 開発フロー（Phase 0 → 1 → 2 → 3 の順序厳守）

## Phase 0：インテイク
依頼内容を要約 → 目的/スコープ/受入条件/制約を整理 → 未確定事項を質問。未確定が残る限り実装提案禁止。

## Phase 1：設計合意
データ構造・DB制約・N+1・トランザクションを明確化。複数案は比較提示。合意後に `/issue` で Issue + ブランチ作成。

## Phase 2：実装計画
変更ファイル一覧・テスト一覧・RED/GREEN/REFACTORの分解・Service分離の要否。「この計画で進めてよいか？」を確認。

## Phase 3：実行
RED → GREEN → REFACTOR 厳守。方針分岐時は停止して確認。各ステップで報告。

---

# TDD強制ルール

* 実装を先に書かない
* 修正時は必ず再現テストを書く
* itは「1関心ごと1例」
* テストが通っただけでは完了ではない（REFACTOR必須）

### 省略条件（すべて満たす場合のみ）
* 1ファイル内の軽微な修正（typo・文言・UIクラス・コメント）
* ロジック・DB・バリデーション・認可/認証・例外処理に影響しない
* 省略しても `rspec` と `rubocop` は必ず実行。迷ったらTDD。

---

# コミット粒度ルール

責務単位で分割。1行で説明できないなら分割を検討。コミット前に分割案を提示し確認を得る。

---

# 禁止事項

* Issueなしで実装開始 / Phase スキップ / テストなし実装 / RuboCop未解消でPR
* ファイルの新規作成・編集後、確認なしに次のステップへ進まない（VS Codeで確認を得てから次へ）
* Controller肥大化 / DB制約の無視

---

# 参照

* 安全ルール → @.claude/rules/git-safety.md / @.claude/rules/file-safety.md / @.claude/rules/production-safety.md
* コマンド → @.claude/commands.md
* 設計方針 → @.claude/design.md
