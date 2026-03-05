---
name: check
description: RSpecとRuboCopをまとめて実行し、PR前の最終確認を行う。
user-invocable: true
disable-model-invocation: false
allowed-tools: Bash
---

# PR前チェック

RSpecとRuboCopをまとめて実行し、結果を報告します。

## 依頼内容

$ARGUMENTS

## 実行手順

### 1. RSpec実行

```bash
docker compose exec web bundle exec rspec
```

### 2. RuboCop実行

```bash
docker compose exec web bundle exec rubocop
```

### 3. 結果報告

以下のフォーマットで報告する：

```
## チェック結果

| 項目 | 結果 | 詳細 |
|---|---|---|
| RSpec | PASS / FAIL | X examples, X failures |
| RuboCop | PASS / FAIL | X offenses detected |

### 総合判定：PR可能 / 要修正
```

### 4. 失敗時の対応

- RSpecが失敗した場合：失敗したテストの内容と原因を報告する
- RuboCopが失敗した場合：違反内容を報告し、自動修正可能か確認する
- 修正は行わず報告のみ。修正が必要な場合は `/execute` で対応する
