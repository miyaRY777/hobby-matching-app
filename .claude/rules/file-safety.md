# ファイル操作安全ルール

## 削除禁止ファイル（確認なしに触れてはいけない）
- `Gemfile` / `Gemfile.lock`
- `docker-compose.yml` / `compose.yml`
- `Dockerfile`
- `config/database.yml`
- `config/routes.rb`（大幅な変更の場合）
- `db/schema.rb`（手動編集禁止、マイグレーション経由のみ）

## 閲覧・出力禁止ファイル
- `.env` / `.env.*`
- `config/credentials.yml.enc`
- `config/master.key`

## rm -rf の完全禁止
いかなる場合も `rm -rf` を実行しない。ファイル削除が必要な場合：
1. 削除対象を一覧で提示する
2. ユーザーの確認を得る
3. 個別に `rm` で削除する（再帰的強制削除は使わない）

## 大量変更の制限
一度に5ファイル以上を変更する場合は、変更一覧を提示して確認を得る。
