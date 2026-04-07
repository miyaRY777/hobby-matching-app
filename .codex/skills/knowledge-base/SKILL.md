---
name: knowledge-base
description: Use when working with the local knowledge-base repository, answering questions from notes, searching notes, capturing inbox memos, distilling inbox files into atomic notes, building MOCs, running quiz-style review, or generating a weekly review for the knowledge base at /Users/miyary777/workspace/miyaRY777/knowledge-base.
---

# Knowledge Base Skill

このスキルは `knowledge-base` リポジトリの Claude 用運用を Codex 向けに置き換える。

対象パス:
- `/Users/miyary777/workspace/miyaRY777/knowledge-base`

まず読むもの:
- 運用の全体像が必要なら `references/workflows.md`
- 出力形式やテンプレートが必要なら `references/templates.md`
- 検索対象や書き込み先を確認したいなら `references/paths.md`

## 使う場面

- ナレッジベースから根拠付きで質問に答える
- ノートや MOC をキーワード検索する
- inbox に新規メモを作る
- inbox を atomic note に distill する
- テーマ別 MOC を作る、更新する
- クイズ形式で復習する
- 週次レビューを作る

## 実行ルール

- 推測で埋めない。不明なら不明と書く
- 参照元のノートやファイルを必ず示す
- 既存ノートに重複しそうなら新規作成より更新提案を優先する
- `distill` と `moc` は、保存前に生成案を見せて確認を取る
- ノート本文はコピペせず、自分の言葉で要約する

## 役割対応

- `knowledge-qa`: `ask` と質問応答を担当
- `note-distiller`: `distill` を担当
- `moc-builder`: `moc` を担当

## コマンド対応

- `capture`: inbox に日付付きメモファイルを作る
- `distill`: inbox を atomic note に分割する
- `moc`: テーマ別の MOC を生成または更新する
- `ask`: 質問に結論と根拠付きで答える
- `search`: 全文検索結果を返す
- `quiz`: 1問ずつ出題して復習候補を管理する
- `weekly-review`: inbox、notes、open questions を棚卸しする

## 作業の基本順

1. `references/paths.md` の対象ディレクトリを確認する
2. 目的に合う workflow を `references/workflows.md` から選ぶ
3. 必要なら `references/templates.md` の形式で出力する
4. 書き込みがある場合は保存前に案を共有する
