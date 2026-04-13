# 設計書：メンバー詳細パネル改善

**日付**: 2026-04-14  
**対象画面**: `shares/show`（マインドマップ + 右側詳細パネル）  
**Issue**: 未作成（Phase 1 設計合意後に作成）

---

## 背景・目的

`shares/show.html.erb` の右側詳細パネル（`rooms/members/show.html.erb`）には以下の問題がある：

1. **「ひとこと」タブと趣味タブが同じ見た目**で、役割の違いが伝わりにくい
2. **初期表示から説明文が見えすぎる**（ひとことタブがデフォルト選択状態）
3. **カードサイズが大きすぎる**

これらを改善し、視認性と情報の役割分担を明確にする。

---

## 受入条件

- [ ] 初期表示でタブがすべて未選択、説明エリアが非表示
- [ ] タブをクリックすると説明エリアが表示される
- [ ] 同じタブを再クリックすると説明エリアが閉じる（トグル）
- [ ] 「💬 ひとこと」タブがアンバー系スタイル、趣味タブは青系スタイル
- [ ] カード全体のサイズが現在より小さくなる
- [ ] `my/profiles/_form.html.erb` の tabs 動作が変わらない

---

## 設計

### 変更ファイル

| ファイル | 変更内容 |
|---|---|
| `app/javascript/controllers/tabs_controller.js` | `defaultOpen` バリュー追加・トグル対応 |
| `app/views/rooms/members/show.html.erb` | サイズ縮小・ひとことスタイル変更・defaultOpen=false |

---

### tabs_controller.js

#### 追加：`defaultOpen` バリュー

```js
static values = { defaultOpen: { type: Boolean, default: true } }
```

- `true`（デフォルト）: 既存動作を維持（`connect()` で最初のタブを選択）
- `false`: 初期状態で全パネル非表示、全タブ未選択

既存の `my/profiles/_form.html.erb` は `defaultOpen` を指定しないため **挙動は変わらない**。

#### 追加：トグル動作

同じタブを再クリックしたとき、選択を解除してパネルを閉じる。

```
// 擬似コード
switch(event):
  index = clickedTabのインデックス
  if index == activeIndex:
    deactivate()  // 全タブ未選択・全パネル非表示
  else:
    activate(index)
```

#### activeIndex の管理

`connect()` 時に `this.activeIndex = null` で初期化。  
`activate(index)` で `this.activeIndex = index` を更新。  
`deactivate()` で `this.activeIndex = null` にリセット。

---

### rooms/members/show.html.erb

#### サイズ縮小

| 項目 | 変更前 | 変更後 |
|---|---|---|
| カード padding | `1.5rem` | `1rem` |
| border-radius | `1.5rem` | `1rem` |
| ユーザー名 font-size | `1.1rem` | `0.95rem` |
| タブボタン font-size | `0.8rem` | `0.75rem` |
| タブボタン padding | `0.35rem 0.85rem` | `0.25rem 0.65rem` |
| パネル min-height | `8rem` | `6rem` |
| パネル font-size | `0.95rem` | `0.875rem` |

#### 「ひとこと」タブスタイル

| 状態 | スタイル |
|---|---|
| 非選択時 | border: `#fbbf24`, color: `#fbbf24`, bg: `rgba(251,191,36,0.12)` |
| 選択時 | bg: `linear-gradient(135deg, #d97706, #b45309)`, color: `#fff` |

趣味タブ（選択時）は現在の青グラデーション（`#2563eb → #1d4ed8`）を維持。

#### テキスト

`💬 ひとこと`（絵文字 + スペース + テキスト）

#### data 属性

```html
<div data-controller="tabs" data-tabs-default-open-value="false">
```

---

## 状態ワイヤー

```
【初期状態】
┌──────────────────────────────┐
│ [◯] miyaRY777                │
│                              │
│ [💬 ひとこと] [葬送] [WT]    │
│              [MH] [Among Us] │
│                              │
└──────────────────────────────┘

【💬 ひとことクリック後】
┌──────────────────────────────┐
│ [◯] miyaRY777                │
│                              │
│ [💬 ひとこと✓] [葬送] [WT]  │  ← amber でハイライト
│               [MH] [Among Us]│
│                              │
│ はじめましての方は...         │
└──────────────────────────────┘

【趣味タブクリック後】
┌──────────────────────────────┐
│ [◯] miyaRY777                │
│                              │
│ [💬 ひとこと] [葬送✓] [WT]  │  ← 青でハイライト
│              [MH] [Among Us] │
│                              │
│ フリーレンが好きです...       │
└──────────────────────────────┘

【選択中のタブを再クリック】
→ 初期状態に戻る（説明エリア非表示）
```

---

## 影響範囲

- `tabs` コントローラーを利用する他箇所（`my/profiles/_form.html.erb`）への影響なし
- `tabs_controller.js` のテストが存在する場合は追加テストが必要
- `rooms/members/show.html.erb` の System Spec（存在する場合）の確認が必要
