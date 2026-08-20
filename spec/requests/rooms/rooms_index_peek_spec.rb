require "rails_helper"

# 責務: 一覧の「覗いてみる / 見る」と、未参加の直接参加。
# 参加モーダルは出さない。
RSpec.describe "GET /rooms 覗いてみる/見る", type: :request do
  let(:current_user) { create(:user) }
  let(:current_profile) { create(:profile, user: current_user) }
  let(:owner_profile) { create(:profile) }
  let!(:unjoined_room) { create(:room, issuer_profile: owner_profile, label: "未参加の部屋", locked: false) }
  let!(:joined_room) { create(:room, issuer_profile: owner_profile, label: "参加済みの部屋", locked: false) }
  let!(:issued_room) { create(:room, issuer_profile: current_profile, label: "自分の部屋", locked: false) }

  before do
    create(:room_membership, room: joined_room, profile: current_profile)
    create(:room_membership, room: issued_room, profile: current_profile)
    sign_in current_user
    get rooms_path
  end

  it "未参加には「覗いてみる」があり、部屋ページへリンクする" do
    row = Nokogiri::HTML(response.body).at_css("#room_#{unjoined_room.id}")
    peek = row.at_css("a[href='#{room_path(unjoined_room)}']")

    expect(peek.text).to include("覗いてみる")
  end

  it "未参加の「参加する」は参加リクエストを送る" do
    row = Nokogiri::HTML(response.body).at_css("#room_#{unjoined_room.id}")
    form = row.at_css("form")

    expect(form[:action]).to eq(mypage_room_memberships_path)
    expect(form.at_css("input[name='room_id']")[:value]).to eq(unjoined_room.id.to_s)
    expect(form.at_css("[type=submit]")[:value]).to eq("参加する")
  end

  it "参加済みには「見る」があり、部屋ページへリンクする" do
    row = Nokogiri::HTML(response.body).at_css("#room_#{joined_room.id}")

    expect(row.text).to include("見る")
    expect(row.at_css("a")[:href]).to eq(room_path(joined_room))
  end

  it "参加済みに「参加する」はない" do
    row = Nokogiri::HTML(response.body).at_css("#room_#{joined_room.id}")

    expect(row.text).not_to include("参加する")
  end

  it "作成した部屋には「見る」があり、部屋ページへリンクする" do
    row = Nokogiri::HTML(response.body).at_css("#room_#{issued_room.id}")

    expect(row.text).to include("見る")
    expect(row.at_css("a")[:href]).to eq(room_path(issued_room))
  end

  it "作成した部屋に「参加する」はない" do
    row = Nokogiri::HTML(response.body).at_css("#room_#{issued_room.id}")

    expect(row.text).not_to include("参加する")
  end

  it "参加モーダルは出ない" do
    expect(response.body).not_to include("data-testid=\"room-modal")
  end
end
