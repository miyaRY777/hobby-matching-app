---
name: design
description: Phase 1 設計合意。データ構造・DB制約・N+1・トランザクション・複数案のトレードオフを整理し、合意を得る。
user-invocable: true
disable-model-invocation: false
allowed-tools: Read, Grep, Glob, Agent, Bash, AskUserQuestion
---

# Phase 1：設計合意

あなたはPhase 1（設計合意）を実行します。**実装には入らないでください。**

## 前提

Phase 0（インテイク）で合意済みの要約・スコープ・受入条件が存在すること。
存在しない場合は「先に /intake を実行してください」と案内して終了する。

## 依頼内容

$ARGUMENTS

## 実行手順

1. `.claude/design.md` を読み、設計方針を再確認する
2. 現在のコードベース（モデル・スキーマ・コントローラ・ルーティング）を調査する
3. 以下の観点で設計を整理する
4. 複数案がある場合はトレードオフを提示し、AskUserQuestionで合意を取る

## 整理する観点

### データ構造
- テーブル追加・カラム追加・マイグレーションの要否
- 既存モデルへの影響

### DB制約
- unique / not null / foreign key / index の要否
- design.md の「DB事故防止制約」に準拠しているか

### N+1
- クエリの発行パターンと includes / preload の設計

### トランザクション
- 複数テーブルへの書き込みがある場合のトランザクション境界

### Service分離
- design.md の「Service分離ポリシー」に該当するか

## 出力フォーマット

### データ構造の変更
- 変更内容（なしの場合は「なし」）

### DB制約
- 追加する制約一覧

### クエリ設計
- 主要クエリとN+1対策

### トランザクション
- 必要 / 不要、必要な場合は境界の説明

### Service分離
- 要 / 不要、要の場合はService名と責務

### 設計案（複数案がある場合）

| | 案A | 案B |
|---|---|---|
| 概要 | ... | ... |
| メリット | ... | ... |
| デメリット | ... | ... |

**推奨案：** 案X（理由）

## ルール

- 合意が取れるまで Phase 2 には進まない
- 推測で設計しない。不明点はAskUserQuestionで質問する
- すべてのコマンドは `docker compose exec web` 経由
