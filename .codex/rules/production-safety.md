# 本番環境保護ルール

## 禁止事項

- `RAILS_ENV=production` を含むコマンド実行
- 本番DBへの接続や操作
- 本番 credentials の編集
- 事前確認なしのデプロイ操作

## DB操作の安全方針

- `db:drop` は実行しない
- `db:migrate` は内容確認後に実行する
- `db:rollback` は影響範囲を確認してから実行する
- `db:seed` は既存データへの影響を確認してから実行する
- DB操作は `docker compose exec web` 経由を基本とする
