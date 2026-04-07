# knowledge-base Templates

## ask 回答

```markdown
## 結論
1〜2文で回答

## 根拠
- [[note-xxx]]: このノートから分かること
- [[note-yyy]]: このノートから分かること

## 補足
追加の文脈

## 次アクション
推奨する次の一手

---
**参照ノート**: [[note-xxx]], [[note-yyy]]
```

情報不足なら:

```markdown
## 回答できない理由
不足理由

## 不足している情報
- まだ見つかっていない情報

## 作るべきノート
- [ ] ノート案
```

## search 結果

```markdown
## 「キーワード」の検索結果（X件）

| ノート | タイトル | マッチ箇所 |
|--------|---------|-----------|
| [[note-...]] | タイトル | Tags / Summary / Body |

---

### 詳細

#### [[note-...]]
> マッチ箇所の抜粋
```

## capture テンプレート

```markdown
# タイトル

**日時**: YYYY-MM-DD
**情報源**: Raycast学習メモ

---

ここにメモを貼る
```

## distill ノート

```markdown
---
id: note-{category}-{short-name}
title: タイトル
created: YYYY-MM-DD
source: [[inbox-file-name]]
---

## Summary
- 要点1
- 要点2
- 要点3

## Tags
#tag1 #tag2

## Links
- [[関連ノート]]

## Body
自分の言葉で要点と背景をまとめる

## Example
コード例を出せる場合はコードを書き、その下に「このコードでは...」で短く説明する
コード例が出しにくい場合は文章の具体例だけを書く

## Action
- [ ] 必要なタスク
```

## MOC

```markdown
# テーママップ

> **このMOCで分かること**: 1行説明

---

## サマリー

| # | 項目 | 概要 | ノート |
|---|------|------|--------|
| 1 | ... | ... | [[note-...]] |

---

## セクション1: グループ名

[[note-...]]

---

## 未決事項（Open Questions）

| 項目 | 期限 | 担当 | ノート |
|------|------|------|--------|
| ... | ... | ... | [[note-open-...]] |

---

## 関連リンク

- [[map-...]]
```

## weekly-review

```markdown
# 週次レビュー（YYYY-MM-DD）

## inbox 棚卸し

### Distill候補
- [ ] YYYY-MM-DD_insight_xxx.md

### 完了済み
- [x] YYYY-MM-DD_insight_xxx.md

## 今週覚えた概念

| 日付 | 概念 | タグ | ノート |
|------|------|------|--------|
| MM/DD | 概念名 | #tag | [[note-...]] |

## 未解決のOpen Questions

| 項目 | MOC |
|------|-----|
| 項目 | [[map-...]] |

## 来週やること
- [ ] distill を進める
- [ ] open question を調べる
- [ ] MOC を更新する
```
