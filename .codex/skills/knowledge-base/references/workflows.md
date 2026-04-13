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
- 本文は生メモのまま保存し、要約や分類はまだしない
- 保存後は、同じファイルをそのまま `distill` の入力として扱う
- 入力テンプレートは `タイトル / 日時 / 元メモ / 関連タグ候補` を基本にする

例:

- 入力が「Stimulus Classes API のメモ」なら
  `knowledge/inbox/2026-04-09_insight_stimulus-classes-api.md` を作る
- この段階では、1ファイルに複数概念が入っていてよい

テンプレート例:

```markdown
# タイトル

**日時**: 2026-04-09
**元メモ**: Raycast
**関連タグ候補**: #frontend #stimulus

---

ここに生メモをそのまま入れる
```

## distill

- inbox ファイルを読む
- アイデアをカテゴリ別に分ける
- 既存 `knowledge/notes/` に重複がないか確認する
- ノート案を表示して確認を取る
- 保存後、必要なら `knowledge/inbox/done/` への移動を提案する
- 1 ファイルに複数概念があれば、1 ノート 1 アイデアで分割する
- 完全に同じ概念が既存ノートにあるなら、新規作成より既存更新を優先する

例:

- `knowledge/inbox/2026-04-09_insight_stimulus-classes-api.md` を読む
- `entry-point`, `css-entry`, `build-output`, `stimulus-classes-property-api` に分割する
- 保存前に 4 本のノート案を見せる

## done

- distill 済みの inbox メモは `knowledge/inbox/done/` に移す
- 移動前に、対応する notes が保存済みか確認する
- 移動前に、保存内容を確認済みか確認する
- 関連ノートへの `Links` や最低限の整理が必要なら、done 前に済ませる
- 移動後は、どの inbox ファイルを done に送ったかユーザーへ伝える

例:

- `knowledge/inbox/2026-04-09_insight_stimulus-classes-api.md` を
  `knowledge/inbox/done/2026-04-09_insight_stimulus-classes-api.md` に移す

## capture-to-done

1. `capture` で生メモを `knowledge/inbox/` に保存する
2. 同じファイルを `distill` で読み、notes 案を作る
3. 保存確認後、`knowledge/notes/` に atomic note を作る
4. 元の inbox ファイルを `done` に移す
5. 新しい概念群が既存テーマに入るなら、関連 MOC の更新候補を確認する

## moc

- テーマに対応する notes を集める
- サマリー表、セクション、未決事項、関連リンクを含む
- 既存 MOC があれば更新差分を意識する
- 保存前に案を見せる
- `distill` で新しい概念群を追加した直後に、関連 MOC があるか確認する

## ask

- 通常質問なら notes を優先して検索する
- `#tag` を含むならタグ検索として一覧化する
- 回答は結論、根拠、補足、次アクションの順にする

## search

- notes、maps、inbox を全文検索する
- 件数を明示する
- マッチ箇所の抜粋を添える

## quiz

- 開始前に、出題候補ノートの `#要復習` 個数と `review_log` 件数が一致しているか確認する
- 開始前チェックは `ruby /Users/miyary777/workspace/miyaRY777/knowledge-base/scripts/review_tag_sync.rb --note PATH --action check --date YYYY-MM-DD` を優先して使う
- 不一致があれば、出題前にどちらを正とするかユーザーに確認する
- タグ指定があれば絞り込む
- 複数問なら同じノートを重複させない
- 1問ずつ出す
- 各問題を出す前に、その問題がどのノートに対応するかを内部で確定し、答え合わせ時はそのノートだけを更新対象にする
- ノート末尾に `<!-- review_log: YYYY-MM-DD,YYYY-MM-DD -->` 形式の HTML コメントを持たせる
- `#要復習` の個数は `review_log` に記録された日付件数と一致させる
- 間違えた、またはスキップしたノートには、その日の日付を `review_log` に1件追加し、`#要復習` も1つ追加する
- `#要復習` は間違えるたびに重複して追加してよい
- その日に追加した `review_log` は、その日中は正解しても消さない
- 翌日以降に正解したときだけ、当日より前の日付を `review_log` から1件外し、対応する `#要復習` も1つ外す
- 外すときは、`review_log` に残っている最古の日付を1件外す
- `review_log` がない既存ノートは、最初に `#要復習` を操作するときに新規作成する
- `review_log` は必ずノート末尾に置く
- `review_log` の日付は古い順に並べる
- `review_log` が空になったら HTML コメントごと削除し、`#要復習` も 0 個にする
- 正誤確定後の更新は手編集より `ruby /Users/miyary777/workspace/miyaRY777/knowledge-base/scripts/review_tag_sync.rb --note PATH --action wrong|correct --date YYYY-MM-DD` を優先する
- タグを付けたら、どのノートを更新したかユーザーに伝える
- タグを外したときも、どのノートを更新したかユーザーに伝える

報告テンプレート:

- `更新したノート: [[note-xxx]]`
- `追加: #要復習 を 1 個 / review_log に 2026-04-09 を 1 件`
- `削除: なし`

または

- `更新したノート: [[note-xxx]]`
- `追加: なし`
- `削除: #要復習 を 1 個 / review_log から 2026-04-08 を 1 件`

例:

- 誤答前
  `## Tags` が `#rails #activesupport #predicate #要復習`
  ノート末尾が `<!-- review_log: 2026-04-08 -->`
- 2026-04-09 に誤答したら
  `## Tags` を `#rails #activesupport #predicate #要復習 #要復習` にする
  ノート末尾を `<!-- review_log: 2026-04-08,2026-04-09 -->` にする
- そのまま 2026-04-09 に正解しても
  当日追加した `2026-04-09` は外さないので変更しない
- 2026-04-10 に正解したら
  `## Tags` を `#rails #activesupport #predicate #要復習` に戻す
  ノート末尾を `<!-- review_log: 2026-04-09 -->` にする

- `review_log` がないノートを 2026-04-09 に誤答したら
  `## Tags` に `#要復習` を1つ追加する
  ノート末尾に `<!-- review_log: 2026-04-09 -->` を新規追加する

## month_quiz

- 開始前に、出題候補ノートの `#要復習` 個数と `review_log` 件数が一致しているか確認する
- 開始前チェックは `ruby /Users/miyary777/workspace/miyaRY777/knowledge-base/scripts/review_tag_sync.rb --note PATH --action check --date YYYY-MM-DD` を優先して使う
- 不一致があれば、出題前にどちらを正とするかユーザーに確認する
- 直近 1 ヶ月で追加または更新した notes を対象にする
- 土日に実施する
- タグ指定があれば絞り込む
- 複数問なら同じノートを重複させない
- 1問ずつ出す
- 各問題を出す前に、その問題がどのノートに対応するかを内部で確定し、答え合わせ時はそのノートだけを更新対象にする
- ノート末尾に `<!-- review_log: YYYY-MM-DD,YYYY-MM-DD -->` 形式の HTML コメントを持たせる
- `#要復習` の個数は `review_log` に記録された日付件数と一致させる
- 間違えた、またはスキップしたノートには、その日の日付を `review_log` に1件追加し、`#要復習` も1つ追加する
- `#要復習` は間違えるたびに重複して追加してよい
- その日に追加した `review_log` は、その日中は正解しても消さない
- 翌日以降に正解したときだけ、当日より前の日付を `review_log` から1件外し、対応する `#要復習` も1つ外す
- 外すときは、`review_log` に残っている最古の日付を1件外す
- `review_log` がない既存ノートは、最初に `#要復習` を操作するときに新規作成する
- `review_log` は必ずノート末尾に置く
- `review_log` の日付は古い順に並べる
- `review_log` が空になったら HTML コメントごと削除し、`#要復習` も 0 個にする
- 正誤確定後の更新は手編集より `ruby /Users/miyary777/workspace/miyaRY777/knowledge-base/scripts/review_tag_sync.rb --note PATH --action wrong|correct --date YYYY-MM-DD` を優先する
- タグを付けたら、どのノートを更新したかユーザーに伝える
- タグを外したときも、どのノートを更新したかユーザーに伝える
- 終了後は要復習候補だけを短い復習メモにまとめてもよい

報告テンプレート:

- `更新したノート: [[note-xxx]]`
- `追加: #要復習 を 1 個 / review_log に 2026-04-09 を 1 件`
- `削除: なし`

または

- `更新したノート: [[note-xxx]]`
- `追加: なし`
- `削除: #要復習 を 1 個 / review_log から 2026-04-08 を 1 件`

## weekly-review

- inbox の未処理ファイルを洗い出す
- 直近 7 日のノートを集計する
- MOC から open questions を拾う
- 来週のアクションを提案する
