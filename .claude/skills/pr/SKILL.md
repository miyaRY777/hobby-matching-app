---
name: pr
description: GitHub PRを作成する。変更内容を分析し、適切なタイトル・サマリーでPRを作成する。
user-invocable: true
disable-model-invocation: false
allowed-tools: Bash, Read, Glob, AskUserQuestion
---

# PR作成

変更内容を分析し、GitHub PRを作成します。

## 依頼内容

$ARGUMENTS

## 実行手順

### 1. 現状確認（並列実行）
- `git status` で未コミットの変更がないか確認
- `git log --oneline main..HEAD` でPRに含まれるコミットを確認
- `git diff main...HEAD --stat` で変更ファイルの概要を確認
- 未コミットの変更がある場合はコミットするか確認する

### 2. リモートへのプッシュ
- `git push -u origin <ブランチ名>` でプッシュ
- プッシュ前にユーザーに確認する

### 3. PR作成
- コミット内容を分析してタイトルとサマリーを作成
- タイトルは70文字以内
- 以下のフォーマットで `gh pr create` を実行：

```
gh pr create --title "タイトル" --body "$(cat <<'EOF'
## Summary
- 変更内容1
- 変更内容2

## Test plan
- [ ] テスト確認事項1
- [ ] テスト確認事項2

## Related
- Issue: #XX（関連Issueがあれば）
EOF
)"
```

### 4. 完了報告
- PR URLを表示する

## ルール

- 未コミットの変更がある場合はPR作成前に対処する
- プッシュ前にユーザーに確認する
- `--force` プッシュは使わない
- RSpec / RuboCop が通っていることを前提とする（未確認なら先に実行を促す）
