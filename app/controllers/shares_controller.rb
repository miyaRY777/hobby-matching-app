class SharesController < ApplicationController
  before_action :authenticate_user!

  def show
    head :ok
  end
end
