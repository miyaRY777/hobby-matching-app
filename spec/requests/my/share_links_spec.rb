require 'rails_helper'

RSpec.describe "My::ShareLinks", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/my/share_links/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/my/share_links/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/my/share_links/update"
      expect(response).to have_http_status(:success)
    end
  end

end
