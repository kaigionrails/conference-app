class Admin::UsersController < AdminController
  # @rbs @users: User::ActiveRecord_Relation
  # @rbs @user: User

  # @rbs return: void
  def index
    scope = User.eager_load(:profile)
    scope = scope.where(role: params[:role]) if User.roles.key?(params[:role])
    scope = scope.name_starts_with(params[:name].to_s) if params[:name].present?
    @users = scope.order(created_at: :asc).page(params[:page])
  end

  # @rbs return: void
  def show
    @user = User.eager_load(profile: {images_attachments: :blob}).find(params[:id])
  end

  # @rbs return: void
  def edit
    @user = User.find(params[:id])
  end

  # @rbs return: void
  def new
    @user = User.new(role: :operator)
  end

  # @rbs return: void
  def create
    user = User.new(role: :operator, name: user_params[:name])
    auth = AuthenticationProviderEmailAndPassword.new(user: user, **user_auth_params)
    ApplicationRecord.transaction do
      user.save!
      auth.save!
    end
    flash[:success] = "Create succeeded"
    redirect_to admin_user_path(user)
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    # A rejected handle or a registered email reaches here through validation,
    # so this is an ordinary path rather than a 500. RecordNotUnique is the
    # backstop for what only the database sees: a row lost to a concurrent
    # insert between the validation and the write.
    flash[:alert] = "Create failed"
    redirect_to new_admin_user_path
  end

  # @rbs return: void
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
    params.require(:user).permit(:name, :role)
  end

  # @rbs return: { email: (String|nil), password: (String|nil), password_confirmation: (String|nil) }
  private def user_auth_params
    params.require(:auth).permit(:email, :password, :password_confirmation)
  end
end
