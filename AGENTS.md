# 最重要ルール（絶対遵守）

- 設計合意前に実装を始めない
- RED -> GREEN -> REFACTOR を基本とする
- すべての確認系コマンドは `docker compose exec web` 経由を優先する
- 完了報告前に、実行したテストや検証結果を明示する
- 不明点や仕様の分岐がある場合は、推測で埋めずに停止して確認する

---

# Codex 作業フロー

## Phase 0: インテイク

- 依頼内容を要約する
- 目的、スコープ、受入条件、制約を整理する
- 未確定事項が大きい場合は、実装前に確認する

## Phase 1: 設計合意

- データ構造、DB制約、責務分離、N+1、トランザクション要否を確認する
- 複数案があるときは、差分とトレードオフを明示する

## Phase 2: 実装計画

- 変更対象ファイルを洗い出す
- 追加・更新するテストを決める
- RED / GREEN / REFACTOR の順に進める

## Phase 3: 実行

- 先に失敗するテストや再現手順を用意する
- 最小変更で通す
- 通ったあとに責務や命名を整える
- 最後に受入条件と実行結果を突き合わせる

---

# TDDルール

- 実装を先に書かない
- 挙動変更やバグ修正では、再現テストを先に書く
- `it` は 1 関心ごとを基本とする
- テストが通るだけでなく、要件を満たしているか確認する

## 省略できるケース

- 文言、コメント、見た目だけの軽微修正
- ロジック、DB、認可、例外処理に影響しない変更
- ただし迷ったらテストを書く

---

# 完了条件

- 変更内容を自分の言葉で説明できる
- 関連テスト、または必要な検証を実行済みである
- 既知の未対応や残リスクがあれば明示する

---

# 安全ルール参照

- Git安全: `./.codex/rules/git-safety.md`
- ファイル安全: `./.codex/rules/file-safety.md`
- 本番保護: `./.codex/rules/production-safety.md`
- コマンドと設計方針: `./.codex/reference.md`
- knowledge-base 運用: `./.codex/skills/knowledge-base/SKILL.md`
- knowledge-base 運用: `./.codex/skills/knowledge-base/SKILL.md`

---

# 補足

- 既存の `CLAUDE.md` は Claude 向け運用として残し、この `AGENTS.md` を Codex 向けの入口とする
- Claude と Codex で共通化できる運用はそろえ、ツール固有の違いだけを分ける

## knowledge-base の扱い

- `knowledge-base` のノート運用や質問応答を行うときは、knowledge-base スキルの手順に従う
- 対象リポジトリは `/Users/miyary777/workspace/miyaRY777/knowledge-base`
- `capture / distill / moc / ask / search / quiz / weekly-review` を Codex 向けに再現している

## knowledge-base の扱い

- `knowledge-base` のノート運用や質問応答を行うときは、knowledge-base スキルの手順に従う
- 対象リポジトリは `/Users/miyary777/workspace/miyaRY777/knowledge-base`
- `capture / distill / moc / ask / search / quiz / weekly-review` を Codex 向けに再現している
