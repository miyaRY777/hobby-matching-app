# 本番環境保護ルール

## 禁止事項
- `RAILS_ENV=production` を含むすべてのコマンド実行
- 本番データベースへの接続・操作
- 本番環境のcredentials編集
- デプロイコマンドの実行（確認なし）

## DB操作の安全ルール
- `db:drop` は実行禁止
- `db:migrate` は実行前にマイグレーション内容を確認
- `db:rollback` は影響範囲を確認してから実行
- `db:seed` は既存データへの影響を確認してから実行
- すべてのDB操作は `docker compose exec web` 経由で行う
