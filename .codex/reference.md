# Codex リファレンス

## コマンド方針

このリポジトリでは、Rails / RSpec / RuboCop / DB操作は `docker compose exec web` 経由を基本とする。

### 開発環境

```bash
docker compose up
docker compose up -d
docker compose down
```

### テスト

```bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rspec spec/models/xxx_spec.rb
docker compose exec web bundle exec rspec spec/system/
```

### RuboCop

```bash
docker compose exec web bundle exec rubocop
docker compose exec web bundle exec rubocop -a
```

### DB操作

```bash
docker compose exec web bundle exec rails db:migrate
docker compose exec web bundle exec rails db:migrate RAILS_ENV=test
docker compose exec web bundle exec rails db:rollback
docker compose exec web bundle exec rails db:seed
```

## 設計方針

- コントローラは薄く保つ
- 複雑な手続きや複数モデル操作は Service を検討する
- ガード節を優先し、深いネストを避ける
- N+1 の有無を確認する
- 可読性を短さより優先する
- 重要な整合性はアプリだけでなく DB 制約でも担保する

## Service 分離の目安

- 2モデル以上をまたぐ
- トランザクションが必要
- 条件分岐が増えている
- コントローラやモデルに置くとテストしづらい
- 一連の手続きを名前付きで表現したい

## 典型的な検証順

1. 変更対象に近い request / model / system spec を追加または更新する
2. 対象テストだけを実行して RED を確認する
3. 実装後に対象テストを通す
4. 必要に応じて RuboCop や関連テストを追加実行する
5. 受入条件と差分を突き合わせる
