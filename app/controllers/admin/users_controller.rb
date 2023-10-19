class Admin::UsersController < AdminController
  def index
    @users = User.eager_load(:profile).order(:id).page(params[:page])
  end
end
