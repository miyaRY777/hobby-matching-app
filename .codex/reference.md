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

## 疑似コマンド運用

Claude Code の `/plan` `/debug` `/check` `/commit` に近い運用を、Codex では以下の意味で扱う。

### PLAN

- Phase 2 の実装計画に対応する
- 変更対象ファイル、追加・更新テスト、RED / GREEN / REFACTOR の順を明示する
- 迷いがある場合は、この段階で停止して合意を取る

### DEBUG

- バグや失敗時の調査フローに対応する
- 先に再現条件、発生箇所、仮説、観察結果を整理する
- 一度に複数の原因を混ぜず、1仮説ずつ検証する
- 3回連続で外したら停止して相談する

### CHECK

- 完了前の検証フローに対応する
- 対象 spec、必要な関連 spec、RuboCop、受入条件との突合を行う
- 「テストが通った」と「要件を満たした」を分けて確認する

### COMMIT

- 責務単位のコミット整理に対応する
- 変更が大きいときは、先にコミット分割案を言語化する
- 1行で説明しにくい変更は分割を検討する
- コミットメッセージは `fix: 日本語の説明` のように prefix を英語、説明を日本語で統一する
