module Admin::UsersHelper
  # @rbs return: Array[Array[String]]
  def user_role_options
    User.roles.keys.map { |role| [role.humanize, role] }
  end
end
