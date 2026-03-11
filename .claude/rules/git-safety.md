# Git安全ルール

## 絶対禁止コマンド
- `git push --force` / `-f`: 他の開発者の変更を上書きする危険がある
- `git reset --hard`: 未保存の変更が完全に失われる
- `git clean -fd`: 未追跡ファイルが完全に削除される
- `git branch -D`: マージされていないブランチを強制削除する
- `git rebase` on shared branches: 共有ブランチの履歴を書き換えない
- `git checkout -- .`: すべての未ステージ変更を破棄する

## 必須確認コマンド
以下のコマンドは実行前に必ずユーザーに確認する：
- `git commit`: コミットメッセージと対象ファイルを提示
- `git push`: プッシュ先ブランチを確認
- `git merge`: マージ元・マージ先を確認
- `git stash drop`: スタッシュ内容を確認

## ブランチ運用
- mainブランチへの直接コミット禁止
- PRを経由せずにmainにマージしない
- ブランチ名はIssue番号を含める（例: feature/123-xxx）
