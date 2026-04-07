# Git安全ルール

## 絶対禁止

- `git push --force` / `git push -f`
- `git reset --hard`
- `git clean -fd`
- `git branch -D`
- 共有ブランチでの `git rebase`
- `git checkout -- .`

## 実行前に確認が必要

- `git commit`
- `git push`
- `git merge`
- `git stash drop`

## 運用方針

- `main` への直接コミットは禁止
- コミット前に対象ファイルとメッセージ案を示す
- ブランチ名は作業内容が分かる形にする
- ユーザーが作った変更を勝手に打ち消さない
