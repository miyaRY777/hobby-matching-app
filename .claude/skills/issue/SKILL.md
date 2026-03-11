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
- 受入条件（チェックリスト）
- ラベル（あれば）

### 2. Issue作成

以下のフォーマットで `gh issue create` を実行する：

```bash
gh issue create --title "タイトル" --body "$(cat <<'EOF'
## 概要
変更内容の説明

## 受入条件
- [ ] 条件1
- [ ] 条件2

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
- GitHub Project「hobby-matching-app」に紐づける
- ブランチ名はIssue番号を含める（例: `feature/123-xxx`）
- main から最新を pull してからブランチを切る
