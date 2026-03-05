---
name: plan
description: Phase 2 実装計画。変更対象ファイル・テスト一覧・RED/GREEN/REFACTORの分解・Service分離の要否を整理する。
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Agent, AskUserQuestion
---

# Phase 2：実装計画

あなたはPhase 2（実装計画）を実行します。**実装には入らないでください。**

## 前提

Phase 1（設計合意）で設計が合意済みであること。
合意がない場合は「先に /design を実行してください」と案内して終了する。

## 依頼内容

$ARGUMENTS

## 実行手順

1. Phase 1 で合意した設計を基に、具体的な実装計画を作成する
2. 変更対象ファイルとテスト一覧を洗い出す
3. RED → GREEN → REFACTOR のステップに分解する
4. 「この計画で進めてよいか？」をAskUserQuestionで確認する

## 出力フォーマット

### 変更対象ファイル一覧

| ファイル | 変更種別 | 内容 |
|---|---|---|
| `path/to/file.rb` | 新規 / 修正 | 概要 |

### テスト一覧

| テストファイル | テスト内容 |
|---|---|
| `spec/...` | 何をテストするか |

### TDDステップ分解

#### Step 1：RED
- 書くテスト内容（失敗することを確認）

#### Step 2：GREEN
- テストを通すための最小実装

#### Step 3：REFACTOR
- リファクタリング対象（あれば）

（複数サイクルがある場合は Step 4, 5, 6... と続ける）

### Service分離

- 要 / 不要
- 要の場合：Service名・責務・インターフェース

## ルール

- 「この計画で進めてよいか？」の確認なしに Phase 3 に進まない
- 推測で計画しない。不明点はAskUserQuestionで質問する
- すべてのコマンドは `docker compose exec web` 経由
