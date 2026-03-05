---
name: issue
description: GitHub Issueを作成する。Phase 0の整理結果を基に、GitHub Projectに紐づくIssueを作成する。
user-invocable: true
disable-model-invocation: false
allowed-tools: Bash, AskUserQuestion
---

# Issue作成

GitHub Issueを作成します。CLAUDE.mdの「Issueを作成してから作業開始」ルールに対応します。

## 依頼内容

$ARGUMENTS

## 実行手順

### 1. Issue内容の確認

Phase 0（インテイク）の結果がある場合はそれを基にする。
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

### 3. 完了報告
- Issue URLを表示する
- 対応するブランチ名を提案する（例：`feature/search-profiles-123`）

## ルール

- Issueタイトルは簡潔に（50文字以内目安）
- 受入条件はチェックリスト形式にする
- GitHub Project「hobby-matching-app」に紐づける
