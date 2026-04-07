# ファイル操作安全ルール

## 確認なしで大きく触れない

- `Gemfile`
- `Gemfile.lock`
- `docker-compose.yml`
- `compose.yml`
- `Dockerfile`
- `config/database.yml`
- `config/routes.rb`
- `db/schema.rb`

## 閲覧・出力しない

- `.env`
- `.env.*`
- `config/credentials.yml.enc`
- `config/master.key`

## 削除ルール

- `rm -rf` は使わない
- 削除が必要なときは対象を列挙し、確認を得てから個別に削除する

## 変更量の目安

- 一度に 5 ファイル以上を変更する場合は、変更対象を先に共有する
- 影響範囲が広い変更は、先に方針を文章でそろえる
