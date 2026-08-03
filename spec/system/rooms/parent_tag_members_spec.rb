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
  let!(:third_profile) { create_member("demo_user3") }
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
    create(:profile_hobby, profile: third_profile, hobby:, description: "third description")
    second_profile.update!(bio: long_bio)
    login_as(viewer_user, scope: :user)
    visit share_path(share_link.token)
  end

  it "親タグ選択で関連ユーザー全員のカードを縦並び表示する" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click

    within("turbo-frame#member_detail") do
      expect(page).to have_css("[data-testid='member-detail-heading']", text: "詳細")
      expect(page).to have_css(
        "[data-testid='parent-tag-member-summary']",
        text: "関連ユーザー：3人"
      )
      expect(parent_tag_member_summary_colors).to eq(
        "backgroundColor" => "rgb(37, 99, 235)",
        "color" => "rgb(255, 255, 255)"
      )
      cards = all("[data-testid='member-card']")
      expect(cards.map { |card| card["data-profile-id"] }).to eq(
        [ first_profile.id, second_profile.id, third_profile.id ].map(&:to_s)
      )
      expect(page).to have_text("demo_user1")
      expect(page).to have_text("demo_user2")
      expect(page).to have_text("demo_user3")
      expect(page).to have_no_css("[data-testid='member-detail-pagination']")
    end

    expect(page).to have_css("#jsmind_container")
  end

  it "個別ユーザー選択で従来の1人表示へ切り替える" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click
    expect(page).to have_text("関連ユーザー：3人")

    find("jmnode[nodeid='p_#{second_profile.id}_pt_#{parent_tag.id}']").click

    within("turbo-frame#member_detail") do
      expect(page).to have_css("[data-testid='member-detail-heading']", text: "詳細")
      expect(page).to have_no_css("[data-testid='parent-tag-member-summary']")
      expect(page).to have_text("demo_user2")
      expect(page).to have_no_text("関連ユーザー：3人")
    end
  end

  it "対象カード内で説明を開いても他ユーザーのカードを維持する" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click

    within(member_card(second_profile)) do
      click_button "Among Us"
      expect(page).to have_text("second description")
    end

    within("turbo-frame#member_detail") do
      expect(page).to have_css("[data-profile-id='#{first_profile.id}']")
      expect(page).to have_css(
        "[data-profile-id='#{second_profile.id}']",
        text: "second description"
      )
      expect(page).to have_css("[data-profile-id='#{third_profile.id}']")
    end
  end

  it "複数ユーザーの説明を同時に開ける" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click

    within(member_card(first_profile)) { click_button "Among Us" }
    within(member_card(second_profile)) { click_button "💬 自己紹介" }

    within(member_card(first_profile)) do
      expect(page).to have_text("first description")
    end
    within(member_card(second_profile)) do
      expect(page).to have_text(long_bio)
    end
  end

  it "展開したカード一覧を右ペイン内で縦スクロールできる" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click
    before_metrics = member_detail_metrics

    within(member_card(first_profile)) { click_button "Among Us" }
    within(member_card(second_profile)) { click_button "💬 自己紹介" }

    after_metrics = member_detail_metrics
    scroll_metrics = scroll_member_detail_to_bottom

    expect(after_metrics["height"]).to be_within(1).of(624)
    expect(after_metrics["height"]).to be_within(1).of(before_metrics["height"])
    expect(after_metrics["panelClientHeight"]).to eq(before_metrics["panelClientHeight"])
    expect(after_metrics["overflowY"]).to eq("auto")
    expect(after_metrics["overscrollBehaviorY"]).to eq("contain")
    expect(after_metrics["scrollHeight"]).to be > before_metrics["scrollHeight"]
    expect(after_metrics["scrollHeight"]).to be > after_metrics["scrollAreaClientHeight"]
    expect(scroll_metrics["scrollTopAfter"]).to be > scroll_metrics["scrollTopBefore"]
    expect(scroll_metrics["panelHeightAfter"]).to be_within(1).of(after_metrics["height"])
    expect(scroll_metrics["windowScrollYAfter"]).to eq(scroll_metrics["windowScrollYBefore"])
    expect(scroll_metrics["documentScrollTopAfter"]).to eq(
      scroll_metrics["documentScrollTopBefore"]
    )
    expect(scroll_metrics["bodyScrollTopAfter"]).to eq(scroll_metrics["bodyScrollTopBefore"])
  end

  it "右ペイン末端のホイール操作を外側ページへ伝播しない" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click
    within(member_card(first_profile)) { click_button "Among Us" }
    within(member_card(second_profile)) { click_button "💬 自己紹介" }

    area = find("[data-testid='member-detail-scroll-area']")
    before_wheel = prepare_scroll_chaining(area)

    expect(before_wheel["innerScrollTop"]).to eq(before_wheel["innerMaxScrollTop"])
    expect(before_wheel["windowScrollY"]).to be > 0
    expect(before_wheel["windowScrollY"]).to be < before_wheel["windowMaxScrollY"]
    expect(before_wheel["wheelOriginInViewport"]).to be(true)

    scroll_from_area(area, before_wheel)
    after_wheel = outer_and_inner_scroll_positions

    expect(after_wheel["innerScrollTop"]).to eq(before_wheel["innerScrollTop"])
    expect(after_wheel["windowScrollY"]).to eq(before_wheel["windowScrollY"])
  end

  it "下側カードのタグを開いても外側ページをスクロールしない" do
    find("jmnode[nodeid='pt_#{parent_tag.id}']").click

    within(member_card(first_profile)) { click_button "Among Us" }
    within(member_card(second_profile)) { click_button "💬 自己紹介" }

    before_click = prepare_lower_card_click(third_profile, "Among Us")
    expect(before_click["windowScrollY"]).to be > 0
    expect(before_click["targetInViewport"]).to be(true)

    within(member_card(third_profile)) { click_button "Among Us" }
    expect(page).to have_text("third description")

    after_click = outer_and_inner_scroll_positions

    expect(after_click["windowScrollY"]).to eq(before_click["windowScrollY"])
  end

  def member_detail_metrics
    page.evaluate_script(<<~JS)
      (() => {
        const panel = document.querySelector('[data-testid="member-detail-panel"]');
        const area = document.querySelector('[data-testid="member-detail-scroll-area"]');
        return {
          height: panel.getBoundingClientRect().height,
          panelClientHeight: panel.clientHeight,
          overflowY: window.getComputedStyle(area).overflowY,
          overscrollBehaviorY: window.getComputedStyle(area).overscrollBehaviorY,
          scrollHeight: area.scrollHeight,
          scrollAreaClientHeight: area.clientHeight
        };
      })()
    JS
  end

  def scroll_member_detail_to_bottom
    page.evaluate_script(<<~JS)
      (() => {
        const panel = document.querySelector('[data-testid="member-detail-panel"]');
        const area = document.querySelector('[data-testid="member-detail-scroll-area"]');
        const metrics = {
          scrollTopBefore: area.scrollTop,
          windowScrollYBefore: window.scrollY,
          documentScrollTopBefore: document.documentElement.scrollTop,
          bodyScrollTopBefore: document.body.scrollTop
        };

        area.scrollTop = area.scrollHeight;

        return {
          ...metrics,
          scrollTopAfter: area.scrollTop,
          panelHeightAfter: panel.getBoundingClientRect().height,
          windowScrollYAfter: window.scrollY,
          documentScrollTopAfter: document.documentElement.scrollTop,
          bodyScrollTopAfter: document.body.scrollTop
        };
      })()
    JS
  end

  def prepare_scroll_chaining(area)
    page.evaluate_script(<<~JS, area)
      ((area) => {
        area.scrollTop = area.scrollHeight;

        const root = document.documentElement;
        const maxWindowScrollY = root.scrollHeight - window.innerHeight;
        window.scrollTo(0, Math.floor(maxWindowScrollY / 2));

        const rect = area.getBoundingClientRect();
        const visibleLeft = Math.max(0, rect.left);
        const visibleRight = Math.min(window.innerWidth, rect.right);
        const visibleTop = Math.max(0, rect.top);
        const visibleBottom = Math.min(window.innerHeight, rect.bottom);
        const wheelOriginX = (visibleLeft + visibleRight) / 2;
        const wheelOriginY = (visibleTop + visibleBottom) / 2;
        return {
          innerScrollTop: area.scrollTop,
          innerMaxScrollTop: area.scrollHeight - area.clientHeight,
          windowScrollY: window.scrollY,
          windowMaxScrollY: maxWindowScrollY,
          wheelOriginXOffset: Math.round(wheelOriginX - (rect.left + rect.width / 2)),
          wheelOriginYOffset: Math.round(wheelOriginY - (rect.top + rect.height / 2)),
          wheelOriginInViewport: visibleLeft < visibleRight && visibleTop < visibleBottom
        };
      })(arguments[0])
    JS
  end

  def scroll_from_area(area, before_wheel)
    origin = Selenium::WebDriver::WheelActions::ScrollOrigin.element(
      area.native,
      before_wheel.fetch("wheelOriginXOffset"),
      before_wheel.fetch("wheelOriginYOffset")
    )
    page.driver.browser.action.scroll_from(origin, 0, 600).perform
  end

  def prepare_lower_card_click(profile, button_text)
    page.evaluate_script(<<~JS, profile.id, button_text)
      ((profileId, text) => {
        const area = document.querySelector('[data-testid="member-detail-scroll-area"]');
        const card = document.querySelector(
          `[data-testid="member-card"][data-profile-id="${profileId}"]`
        );
        const button = Array.from(card.querySelectorAll('button')).find(
          (candidate) => candidate.textContent.trim() === text
        );

        area.scrollTop = area.scrollHeight;
        button.scrollIntoView({ block: 'center' });

        const rect = button.getBoundingClientRect();
        return {
          windowScrollY: window.scrollY,
          innerScrollTop: area.scrollTop,
          targetInViewport: rect.top >= 0 && rect.bottom <= window.innerHeight
        };
      })(arguments[0], arguments[1])
    JS
  end

  def outer_and_inner_scroll_positions
    page.evaluate_script(<<~JS)
      (() => {
        const area = document.querySelector('[data-testid="member-detail-scroll-area"]');
        return {
          windowScrollY: window.scrollY,
          innerScrollTop: area.scrollTop
        };
      })()
    JS
  end

  def member_card(profile)
    find("[data-testid='member-card'][data-profile-id='#{profile.id}']")
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

  def create_member(nickname)
    profile = create(:profile, user: create(:user, nickname:))
    create(:room_membership, room:, profile:)
    profile
  end
end
