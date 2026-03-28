require "rails_helper"

RSpec.describe "OGP meta tags", type: :request do
  describe "GET /" do
    before { get root_path }

    it "og:titleが設定されている" do
      expect(response.body).to include('<meta property="og:title" content="Hobby Matching"')
    end

    it "og:descriptionが設定されている" do
      expect(response.body).to include('<meta property="og:description" content="誰と、どんな話が合う？共通の趣味でつながろう"')
    end

    it "og:typeが設定されている" do
      expect(response.body).to include('<meta property="og:type" content="website"')
    end

    it "og:urlが設定されている" do
      expect(response.body).to include('<meta property="og:url"')
    end

    it "og:imageが設定されている" do
      expect(response.body).to include('<meta property="og:image"')
    end

    it "og:site_nameが設定されている" do
      expect(response.body).to include('<meta property="og:site_name" content="Hobby Matching"')
    end

    it "og:localeが設定されている" do
      expect(response.body).to include('<meta property="og:locale" content="ja_JP"')
    end

    it "twitter:cardが設定されている" do
      expect(response.body).to include('<meta name="twitter:card" content="summary_large_image"')
    end

    it "twitter:titleが設定されている" do
      expect(response.body).to include('<meta name="twitter:title" content="Hobby Matching"')
    end

    it "twitter:descriptionが設定されている" do
      expect(response.body).to include('<meta name="twitter:description" content="誰と、どんな話が合う？共通の趣味でつながろう"')
    end

    it "twitter:imageが設定されている" do
      expect(response.body).to include('<meta name="twitter:image"')
    end

    it "meta descriptionが設定されている" do
      expect(response.body).to include('<meta name="description" content="誰と、どんな話が合う？共通の趣味でつながろう"')
    end
  end
end
