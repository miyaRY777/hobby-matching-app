# Dark Scrollbars Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (\`- [ ]\`) syntax for tracking.

**Goal:** 共有ページのマインドマップとメンバー詳細のスクロールバーを、通常時はほぼ見えずホバー時だけ控えめに見える角丸のダークスタイルへ変更する。

**Architecture:** 共有ページでのみ読み込まれる \`jsmind.css\` に再利用可能な \`.dark-scrollbar\` と、jsMindが動的生成する内部要素を対象にする \`.dark-scrollbar-host\` のスタイルを定義する。初期表示とTurbo Frame差し替え後のすべてのメンバー詳細スクロール領域に同じクラスを付与し、ほかの画面へ影響を広げない。

**Tech Stack:** Rails 7.2、ERB、CSS、RSpec、Capybara、Docker Compose

## Global Constraints

- 通常時はレールを透明にし、つまみもほぼ目立たない濃さにする。
- 対象領域のホバー時は、つまみを控えめなスレートグレーで表示する。
- スクロールバー幅は6pxとし、つまみは角丸にする。
- Chrome・BraveなどのWebKit/Blink系ブラウザとFirefoxに対応する。
- 縦・横スクロールの操作と既存レイアウトを維持する。
- 共有ページ以外へ適用しない。
- 依存関係は追加しない。

---

## File Structure

- Modify: \`app/views/shares/show.html.erb\` — マインドマップのホストと初期メンバー詳細へ専用クラスを付ける。
- Modify: \`app/views/rooms/members/show.html.erb\` — 個人カードへ差し替えた後も専用クラスを維持する。
- Modify: \`app/views/rooms/parent_tag_members/index.html.erb\` — 親タグ関連ユーザー一覧へ差し替えた後も専用クラスを維持する。
- Modify: \`app/assets/stylesheets/jsmind.css\` — 共有ページ用のFirefox・WebKit/Blink対応スクロールバースタイルを定義する。
- Modify: \`spec/views/shares/show.html.erb_spec.rb\` — 初期HTMLのクラス契約を検証する。
- Modify: \`spec/requests/rooms/members_show_spec.rb\` — 個人カード応答のクラス契約を検証する。
- Modify: \`spec/requests/rooms/parent_tag_members_index_spec.rb\` — 親タグ関連ユーザー応答のクラス契約を検証する。

### Task 1: 共有ページ限定のダークスクロールバー

**Files:**
- Modify: \`spec/views/shares/show.html.erb_spec.rb:15-42\`
- Modify: \`spec/requests/rooms/members_show_spec.rb:32-38\`
- Modify: \`spec/requests/rooms/parent_tag_members_index_spec.rb:40-55\`
- Modify: \`app/views/shares/show.html.erb:53-68\`
- Modify: \`app/views/rooms/members/show.html.erb:1-10\`
- Modify: \`app/views/rooms/parent_tag_members/index.html.erb:1-20\`
- Modify: \`app/assets/stylesheets/jsmind.css:9-25\`

**Interfaces:**
- Consumes: jsMindが \`#jsmind_container\` 内へ生成する \`.jsmind-inner\`、Turbo Frameが差し替える \`[data-testid="member-detail-scroll-area"]\`。
- Produces: \`.dark-scrollbar-host\` は子孫の \`.jsmind-inner\` を装飾し、\`.dark-scrollbar\` はクラスを持つスクロール要素自身を装飾する。

- [ ] **Step 1: 初期表示とTurbo Frame応答のクラス契約テストを書く**

\`spec/views/shares/show.html.erb_spec.rb\` の末尾へ次を追加する。

\`\`\`ruby
context "スクロール領域を描画する場合" do
  let(:locked) { false }
  let(:viewer_profile) { create(:profile) }

  it "共有ページ限定のスクロールバー用クラスを付与する" do
    render

    expect(rendered).to have_css("#jsmind_container.dark-scrollbar-host")
    expect(rendered).to have_css('[data-testid="member-detail-scroll-area"].dark-scrollbar')
  end
end
\`\`\`

\`spec/requests/rooms/members_show_spec.rb\` の「部屋のメンバーであれば200を返す」例へ次の期待値を追加する。

\`\`\`ruby
expect(response.body).to include('data-testid="member-detail-scroll-area"')
expect(response.body).to include("dark-scrollbar")
\`\`\`

\`spec/requests/rooms/parent_tag_members_index_spec.rb\` の「プロフィールID昇順で関連ユーザー全員を表示する」例へ次の期待値を追加する。

\`\`\`ruby
expect(response.body).to include('data-testid="member-detail-scroll-area"')
expect(response.body).to include("dark-scrollbar")
\`\`\`

- [ ] **Step 2: Docker経由でテストがREDになることを確認する**

Run:

\`\`\`bash
docker compose exec web bundle exec rspec spec/views/shares/show.html.erb_spec.rb spec/requests/rooms/members_show_spec.rb spec/requests/rooms/parent_tag_members_index_spec.rb
\`\`\`

Expected: 3件の新しい期待値が \`dark-scrollbar-host\` または \`dark-scrollbar\` 不在によりFAILする。

- [ ] **Step 3: 対象ビューへ専用クラスを付与する**

\`app/views/shares/show.html.erb\` の \`#jsmind_container\` を次のクラスへ変更する。

\`\`\`erb
class="dark-scrollbar-host rounded-[20px]"
\`\`\`

同ファイルの \`[data-testid="member-detail-scroll-area"]\` を次へ変更する。

\`\`\`erb
<div class="dark-scrollbar min-h-0 flex-1 overflow-y-auto"
     data-testid="member-detail-scroll-area">
\`\`\`

\`app/views/rooms/members/show.html.erb\` の対象要素を次へ変更する。

\`\`\`erb
<div class="dark-scrollbar min-h-0 flex-1 overflow-y-auto"
     data-testid="member-detail-scroll-area">
\`\`\`

\`app/views/rooms/parent_tag_members/index.html.erb\` の対象要素を次へ変更する。

\`\`\`erb
<div class="dark-scrollbar min-h-0 flex-1 space-y-4 overflow-y-auto"
     data-testid="member-detail-scroll-area"
     style="overscroll-behavior-y: contain;">
\`\`\`

- [ ] **Step 4: 通常時とホバー時のスクロールバーCSSを実装する**

\`app/assets/stylesheets/jsmind.css\` の \`.jsmind-inner\` 基本定義の後へ次を追加する。

\`\`\`css
.dark-scrollbar,
.dark-scrollbar-host .jsmind-inner {
    scrollbar-color: rgba(71, 85, 105, 0.14) transparent;
    scrollbar-width: thin;
}

.dark-scrollbar:hover,
.dark-scrollbar-host:hover .jsmind-inner {
    scrollbar-color: rgba(100, 116, 139, 0.55) transparent;
}

.dark-scrollbar::-webkit-scrollbar,
.dark-scrollbar-host .jsmind-inner::-webkit-scrollbar {
    width: 6px;
    height: 6px;
}

.dark-scrollbar::-webkit-scrollbar-track,
.dark-scrollbar-host .jsmind-inner::-webkit-scrollbar-track {
    background: transparent;
}

.dark-scrollbar::-webkit-scrollbar-thumb,
.dark-scrollbar-host .jsmind-inner::-webkit-scrollbar-thumb {
    background-color: rgba(71, 85, 105, 0.14);
    border-radius: 9999px;
}

.dark-scrollbar:hover::-webkit-scrollbar-thumb,
.dark-scrollbar-host:hover .jsmind-inner::-webkit-scrollbar-thumb {
    background-color: rgba(100, 116, 139, 0.55);
}
\`\`\`

- [ ] **Step 5: 関連RSpecがGREENになることを確認する**

Run:

\`\`\`bash
docker compose exec web bundle exec rspec spec/views/shares/show.html.erb_spec.rb spec/requests/rooms/members_show_spec.rb spec/requests/rooms/parent_tag_members_index_spec.rb spec/system/shares/layout_stability_spec.rb spec/system/rooms/parent_tag_members_spec.rb
\`\`\`

Expected: 全件PASSし、既存の横幅安定性とメンバー詳細スクロール操作に回帰がない。

- [ ] **Step 6: Braveの実画面で見た目と操作を確認する**

共有ページを開き、次を確認する。

1. マインドマップの縦・横レールが白く表示されない。
2. マインドマップへホバーすると、角丸のスレート色のつまみが控えめに見える。
3. メンバー詳細の縦レールが白く表示されない。
4. メンバー詳細へホバーすると、角丸のスレート色のつまみが控えめに見える。
5. マインドマップの縦・横スクロールと、メンバー詳細の縦スクロールが操作できる。
6. 個人カードと親タグ関連ユーザー一覧へ切り替えても同じ表示が維持される。

- [ ] **Step 7: 全体検証を実行する**

Run:

\`\`\`bash
docker compose exec web bundle exec rspec
docker compose exec web bundle exec rubocop
git diff --check
\`\`\`

Expected: RSpec全件PASS、RuboCop offense 0件、\`git diff --check\` 出力なし。

- [ ] **Step 8: 実装をコミットする**

コミット前に対象7ファイルだけを提示して承認を得る。

\`\`\`bash
git add app/assets/stylesheets/jsmind.css app/views/shares/show.html.erb app/views/rooms/members/show.html.erb app/views/rooms/parent_tag_members/index.html.erb spec/views/shares/show.html.erb_spec.rb spec/requests/rooms/members_show_spec.rb spec/requests/rooms/parent_tag_members_index_spec.rb
git commit -m "fix: 共有ページのスクロールバーをダークUIに合わせる #286"
\`\`\`
