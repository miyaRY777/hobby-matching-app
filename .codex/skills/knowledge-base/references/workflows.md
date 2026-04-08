# knowledge-base Workflows

## CODE サイクル

1. Collect
   inbox にメモを作る、または貼り付ける
2. Distill
   inbox を 1 ノート 1 アイデアの notes に変換する
3. Connect
   notes をまたぐ索引として MOC を作る
4. Use
   ask、search、quiz、weekly-review で使い回す

## capture

- 入力タイトルから `YYYY-MM-DD_insight_{short-title}.md` を作る
- 保存先は `knowledge/inbox/`
- テンプレートは最小限にする

## distill

- inbox ファイルを読む
- アイデアをカテゴリ別に分ける
- 既存 `knowledge/notes/` に重複がないか確認する
- ノート案を表示して確認を取る
- 保存後、必要なら `knowledge/inbox/done/` への移動を提案する

## moc

- テーマに対応する notes を集める
- サマリー表、セクション、未決事項、関連リンクを含む
- 既存 MOC があれば更新差分を意識する
- 保存前に案を見せる

## ask

- 通常質問なら notes を優先して検索する
- `#tag` を含むならタグ検索として一覧化する
- 回答は結論、根拠、補足、次アクションの順にする

## search

- notes、maps、inbox を全文検索する
- 件数を明示する
- マッチ箇所の抜粋を添える

## quiz

- タグ指定があれば絞り込む
- 複数問なら同じノートを重複させない
- 1問ずつ出す
- 間違えた、またはスキップしたノートは `#要復習` 候補として扱う

## month_quiz

- 直近 1 ヶ月で追加または更新した notes を対象にする
- 土日に実施する
- タグ指定があれば絞り込む
- 複数問なら同じノートを重複させない
- 1問ずつ出す
- 間違えた、またはスキップしたノートは `#要復習` 候補として扱う
- 終了後は要復習候補だけを短い復習メモにまとめてもよい

## weekly-review

- inbox の未処理ファイルを洗い出す
- 直近 7 日のノートを集計する
- MOC から open questions を拾う
- 来週のアクションを提案する
