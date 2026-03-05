---
name: commit
description: 変更内容を確認し、適切なコミットメッセージでgit commitを作成する。
user-invocable: true
disable-model-invocation: false
allowed-tools: Bash, Read, Glob
---

# コミット作成

変更内容を確認し、適切なコミットメッセージでコミットを作成します。

## 依頼内容

$ARGUMENTS

## 実行手順

### 1. 現状確認（並列実行）
- `git status` で変更ファイルを確認
- `git diff` でステージ前の差分を確認
- `git diff --cached` でステージ済みの差分を確認
- `git log --oneline -10` で直近のコミットスタイルを確認

### 2. コミットメッセージ作成
- 直近のコミットメッセージのスタイルに合わせる
- 変更の種類に応じたプレフィックスを使う：
  - `feat:` 新機能
  - `fix:` バグ修正
  - `refactor:` リファクタリング
  - `test:` テスト追加/修正
  - `docs:` ドキュメント
  - `chore:` その他（設定、依存関係など）
- 簡潔で「なぜ」がわかるメッセージにする

### 3. コミット実行
- 対象ファイルを `git add` する（`git add .` は使わない）
- コミットメッセージはHEREDOCで渡す
- `.env` やクレデンシャルファイルは絶対にコミットしない

### 4. 確認
- `git status` でコミット後の状態を確認

## ルール

- `git add .` や `git add -A` は使わない。ファイルを個別に指定する
- `--no-verify` は使わない
- `--amend` はユーザーが明示的に指示した場合のみ
- 機密ファイルをコミットしない
