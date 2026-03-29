---
name: execute
description: Phase 3 実行。TDD（RED→GREEN→REFACTOR）を厳守して実装を進める。
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Edit, Write, Grep, Glob, Bash, Agent, AskUserQuestion
---

# Phase 3：実行

あなたはPhase 3（実行）を実行します。TDDを厳守してください。

## 前提

Phase 2（実装計画）で計画が承認済みであること。
承認がない場合は「先に /plan を実行してください」と案内して終了する。

## 依頼内容

$ARGUMENTS

## 実行手順

Phase 2 で合意した計画に従い、以下のサイクルを繰り返す：

### 1. RED（テストを先に書く）
- 失敗するテストを書く
- `docker compose exec web bundle exec rspec <対象ファイル>` で失敗を確認する
- 失敗出力を報告する

### 2. GREEN（最小実装）
- テストが通る最小限のコードを書く
- `docker compose exec web bundle exec rspec <対象ファイル>` で成功を確認する
- 成功を報告する

### 3. REFACTOR
- コードの改善点があればリファクタリングする
- サブエージェント（rails-reviewer / performance-checker）を並列実行する
- 指摘があれば対応し、ユーザーに報告する
- テストが引き続き通ることを確認する
- 改善内容を報告する

### 4. 次のサイクルへ
- 計画の次のステップへ進む
- 方針が分岐した場合はAskUserQuestionで確認する

## 各ステップの報告フォーマット

```
## Step N：RED / GREEN / REFACTOR

**何をしたか：** ...
**影響範囲：** ...
**次にやること：** ...
```

## 完了条件

すべてのステップが完了したら：

1. `docker compose exec web bundle exec rspec` で全テスト通過を確認
2. `docker compose exec web bundle exec rubocop` で違反なしを確認
3. 結果を報告する

## ルール

- 実装を先に書かない（テストファースト）
- 途中で方針が分岐したら停止してAskUserQuestionで確認する
- 高リスク操作（DB変更・既存テスト修正など）前は必ず確認する
- すべてのコマンドは `docker compose exec web` 経由
- TDD省略条件（CLAUDE.md参照）に該当する場合のみ省略可
