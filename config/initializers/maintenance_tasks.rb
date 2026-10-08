# Records who started a run. The proc runs in the controllers of the engine, which inherit from
# ActionController::Base, so the user is looked up from the session instead of current_user.
MaintenanceTasks.metadata = -> do
  user = User.find_by(id: session[:user_id])
  {user_id: user&.id, user_name: user&.name}
end
