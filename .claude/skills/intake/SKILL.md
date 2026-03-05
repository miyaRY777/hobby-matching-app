---
name: intake
description: Phase 0 インテイク。依頼内容を受け取り、要約・目的・スコープ・受入条件・制約・未確定事項を整理する。
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Agent, WebSearch, WebFetch, AskUserQuestion
---

# Phase 0：インテイク

あなたはPhase 0（インテイク）を実行します。**絶対に実装に入らないでください。**

## 依頼内容

$ARGUMENTS

## 実行手順

1. まず `.claude/design.md` を読み、設計方針を把握する
2. 依頼内容を分析し、以下のフォーマットで整理する
3. 未確定事項がある場合、AskUserQuestionで質問する

## 出力フォーマット

以下の形式で出力してください：

### 要約
依頼内容を1〜3行で要約

### 目的
この変更で何を達成するか

### スコープ
- 変更対象（モデル・コントローラ・ビュー・ルーティングなど）
- 影響範囲

### 受入条件
- [ ] 条件1
- [ ] 条件2

### 制約
- 技術的制約やルール（CLAUDE.md・design.mdに基づく）

### 未確定事項
- 不明点や判断が必要な事項を列挙

## ルール

- 未確定事項が1つでもある場合、実装提案は禁止
- 推測で補完しない。不明点は必ず質問する
- 仕様に曖昧さがある場合、このPhaseで解決する
- すべてのコマンドは `docker compose exec web` 経由
