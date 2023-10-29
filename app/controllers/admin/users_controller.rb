class Admin::UsersController < AdminController
  def index
    @users = User.eager_load(:profile).order(:id).page(params[:page])
  end

  def show
    @user = User.eager_load(profile: { images_attachments: :blob }).find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    user = User.find(params[:id])
    if user.update(user_params)
      flash[:success] = "Update succeeded"
      redirect_to admin_user_path(user)
    else
      flash[:alert] = "Update failed"
      redirect_to edit_admin_user_path(user)
    end
  end

  private def user_params
    params.require(:user).permit(:role)
  end
end
