module Admin::UsersHelper
  def user_role_options
    User.roles.keys.map { |role| [role.humanize, role] }
  end
end
