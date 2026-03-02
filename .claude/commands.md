# コマンドリファレンス（Docker前提）

> すべてのコマンドは `docker compose exec web` 経由で実行する。

## 開発環境

```bash
docker compose up        # 起動
docker compose up -d     # バックグラウンド起動
docker compose down      # 停止
```

## テスト

```bash
docker compose exec web bundle exec rspec                          # 全テスト
docker compose exec web bundle exec rspec spec/models/xxx_spec.rb  # ファイル指定
docker compose exec web bundle exec rspec spec/system/             # ディレクトリ指定
```

## RuboCop

```bash
docker compose exec web bundle exec rubocop    # チェック
docker compose exec web bundle exec rubocop -a # 自動修正
```

## DB操作

```bash
docker compose exec web bundle exec rails db:migrate
docker compose exec web bundle exec rails db:migrate RAILS_ENV=test
docker compose exec web bundle exec rails db:rollback
docker compose exec web bundle exec rails db:seed
```

## Rails コンソール

```bash
docker compose exec web bundle exec rails console
```
