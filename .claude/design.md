# コード設計方針

## 設計思想

* コントローラは薄く保つ
* ビジネスロジックはServiceへ
* ネストは浅く（ガード節優先）
* マジックナンバー禁止
* N+1は必ず検討
* 可読性 > 短さ

## Service分離ポリシー

以下に該当する場合は必ず `app/services/` に切り出す：

* 2モデル以上を跨ぐ
* トランザクションが必要
* 手続きの流れ中心
* 条件分岐が増えた
* コントローラに置くとテストしづらい

## DB事故防止制約

重要な整合性は **必ずDBで保証**（アプリロジックだけに依存しない）：

* `profiles.user_id` unique
* `hobbies.name` unique
* `profile_hobbies(profile_id, hobby_id)` unique
* `room_memberships(room_id, profile_id)` unique
* `share_links.token` unique
* `share_links.room_id` unique（1 room : 1 link を保証する場合）
