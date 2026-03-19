---
name: issue
description: GitHub Issueと作業ブランチを作成する。Phase 1の設計合意後に実行する。
user-invocable: true
disable-model-invocation: false
allowed-tools: Bash, AskUserQuestion
---

# Issue + 作業ブランチ作成

Phase 1（設計合意）完了後に、GitHub Issue と作業ブランチを作成します。

## 依頼内容

$ARGUMENTS

## 実行手順

### 1. Issue内容の確認

Phase 0〜1 の合意内容を基にする。
ない場合は $ARGUMENTS からIssue内容を整理する。

以下をAskUserQuestionで確認する：
- Issueタイトル
- 各セクションの内容に過不足がないか
- ラベル（あれば）

### 2. Issue作成

以下のフォーマットで `gh issue create` を実行する：

```bash
gh issue create --title "タイトル" --body "$(cat <<'EOF'
## 目的
- 何のための機能か
- 何を解決したいのか

## 背景
- 現状の課題や経緯

## 設計
- なぜその実装にするのか
- どのモデル・画面・責務を触るのか

## 動き（ユーザーフロー）
1. ユーザーが〜する
2. 内部で〜が起こる
3. 結果として〜になる

## スコープ
- 今回実装する内容

## スコープ外
- 今回は対象外とする内容

## 受入条件
- [ ] 条件1
- [ ] 条件2

## 検証（確認項目）
- [ ] 正常系: 期待通りの動作
- [ ] 異常系: エラーケースの処理
- [ ] 既存機能に影響しない

## 改善（既知の課題・今後の検討）
- 今の実装の弱い点
- 次に直すならどこか

## 制約
- 制約事項（あれば）
EOF
)" --project "hobby-matching-app"
```

### 3. 作業ブランチ作成

Issue番号を含むブランチを main から作成する：

```bash
git checkout main && git pull origin main && git checkout -b feature/<Issue番号>-<短い説明>
```

ブランチ名の例：`feature/114-dashboard-ui-consistency`

### 4. 完了報告

- Issue URL を表示する
- 作成したブランチ名を表示する

## ルール

- Issueタイトルは簡潔に（50文字以内目安）
- 受入条件はチェックリスト形式にする
- 検証項目には正常系・異常系・既存影響を含める
- 改善セクションで既知の課題や将来の拡張ポイントを記載する
- GitHub Project「hobby-matching-app」に紐づける
- ブランチ名はIssue番号を含める（例: `feature/123-xxx`）
- main から最新を pull してからブランチを切る
