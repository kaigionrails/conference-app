class UsersController < ApplicationController
  def show
    @user = User.find_by!(name: params[:username])
  end
end
