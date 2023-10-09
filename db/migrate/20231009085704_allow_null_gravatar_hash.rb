class AllowNullGravatarHash < ActiveRecord::Migration[7.0]
  def change
    change_column_null :speakers, :gravatar_hash, true
  end
end
