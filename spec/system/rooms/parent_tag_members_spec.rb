require "rails_helper"

RSpec.describe "親タグ関連ユーザー表示", type: :system, js: true do
  let(:viewer_user) { create(:user, nickname: "viewer") }
  let(:viewer_profile) { create(:profile, user: viewer_user) }
  let(:room) { create(:room, issuer_profile: viewer_profile, room_type: :chat) }
  let(:share_link) { create(:share_link, room:, expires_at: 1.hour.from_now) }
  let(:parent_tag) { create(:parent_tag, name: "ゲーム", room_type: :chat) }
  let(:hobby) { create(:hobby, name: "Among Us") }
  let!(:first_profile) { create_member("demo_user1") }
  let!(:second_profile) { create_member("demo_user2") }
  let(:long_bio) { ("長い自己紹介文です。\n" * 45).strip }

  before do
    create(:room_membership, room:, profile: viewer_profile)
    create(:hobby_parent_tag, hobby:, parent_tag:)
    create(:profile_hobby, profile: first_profile, hobby:, description: "first description")
    create(
      :profile_hobby,
      profile: second_profile,
      hobby:,
      description: "second description " * 10
    )
    second_profile.update!(bio: long_bio)
    login_as(viewer_user, scope: :user)
    visit share_path(share_link.token)
  end

  it "親タグ選択とページ送りで関連ユーザーを1人ずつ表示する" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click

    within("turbo-frame#member_detail") do
      expect(page).to have_css("[data-testid='member-detail-heading']", text: "詳細")
      expect(page).to have_css(
        "[data-testid='parent-tag-member-summary']",
        text: "関連ユーザー：2人"
      )
      expect(parent_tag_member_summary_colors).to eq(
        "backgroundColor" => "rgb(37, 99, 235)",
        "color" => "rgb(255, 255, 255)"
      )
      expect(page).to have_text("demo_user1")
      expect(page).to have_no_text("demo_user2")
      click_link "次へ ›"
      expect(page).to have_text("demo_user2")
      expect(page).to have_no_text("demo_user1")
      expect(page).to have_css(
        "[data-testid='parent-tag-member-summary']",
        text: "関連ユーザー：2人"
      )
    end

    expect(page).to have_css("#jsmind_container")
  end

  it "個別ユーザー選択で従来の1人表示へ切り替える" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click
    expect(page).to have_text("関連ユーザー：2人")

    find("jmnode[nodeid='p_#{second_profile.id}_pt_#{parent_tag.id}']").click

    within("turbo-frame#member_detail") do
      expect(page).to have_css("[data-testid='member-detail-heading']", text: "詳細")
      expect(page).to have_no_css("[data-testid='parent-tag-member-summary']")
      expect(page).to have_text("demo_user2")
      expect(page).to have_no_text("関連ユーザー：2人")
    end
  end

  it "ページ移動後のカードでも趣味説明を開ける" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click

    within("turbo-frame#member_detail") do
      click_link "次へ ›"
      expect(page).to have_text("demo_user2")
    end

    within("turbo-frame#member_detail") do
      click_button "Among Us"
      expect(page).to have_text("second description")
    end
  end

  it "説明文量が変わってもページネーションを右ペイン下部に固定する" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click

    within("turbo-frame#member_detail") do
      click_button "Among Us"
      first_metrics = member_detail_metrics

      click_link "次へ ›"
      expect(page).to have_text("demo_user2")
      click_button "💬 自己紹介"
      expect(page).to have_text(long_bio)
      second_metrics = member_detail_metrics

      expect(first_metrics["offset"]).to be_within(1).of(first_metrics["paddingBottom"])
      expect(second_metrics["offset"]).to be_within(1).of(second_metrics["paddingBottom"])
      expect(second_metrics["offset"]).to be_within(1).of(first_metrics["offset"])
      expect(second_metrics["overflowY"]).to eq("auto")
      expect(second_metrics["scrollHeight"]).to be > second_metrics["clientHeight"]
    end
  end

  def create_member(nickname)
    profile = create(:profile, user: create(:user, nickname:))
    create(:room_membership, room:, profile:)
    profile
  end

  def member_detail_metrics
    page.evaluate_script(<<~JS)
      (() => {
        const panel = document.querySelector('[data-testid="member-detail-panel"]');
        const pagination = document.querySelector('[data-testid="member-detail-pagination"]');
        const scrollArea = document.querySelector('[data-testid="member-detail-scroll-area"]');
        return {
          offset: panel.getBoundingClientRect().bottom - pagination.getBoundingClientRect().bottom,
          paddingBottom: parseFloat(window.getComputedStyle(panel).paddingBottom),
          overflowY: window.getComputedStyle(scrollArea).overflowY,
          scrollHeight: scrollArea.scrollHeight,
          clientHeight: scrollArea.clientHeight
        };
      })()
    JS
  end

  def parent_tag_member_summary_colors
    page.evaluate_script(<<~JS)
      (() => {
        const summary = document.querySelector('[data-testid="parent-tag-member-summary"]');
        const styles = window.getComputedStyle(summary);
        return {
          backgroundColor: styles.backgroundColor,
          color: styles.color
        };
      })()
    JS
  end
end
