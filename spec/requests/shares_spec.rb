require 'rails_helper'

RSpec.describe "Shares", type: :request do
  describe "GET /show" do
    it "returns http success" do
      get "/shares/show"
      expect(response).to have_http_status(:success)
    end
  end

end
