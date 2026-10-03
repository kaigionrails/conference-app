require "rails_helper"

RSpec.describe "ProfileImages", type: :request do
  describe "DELETE /profiles/:profile_id/profile_images/:id" do
    let(:user) { FactoryBot.create(:user) }
    let!(:profile) { FactoryBot.create(:profile, :with_image, user: user) }
    before { sign_in(user) }

    it "deletes the user's own image" do
      image = profile.images.first

      expect { delete "/profiles/#{profile.id}/profile_images/#{image.id}" }
        .to change { profile.reload.images.count }.from(1).to(0)
      expect(flash[:success]).to be_present
      expect(response).to redirect_to(edit_profile_path(profile))
    end

    it "leaves someone else's image alone, and says nothing was deleted" do
      other_image = FactoryBot.create(:profile, :with_image).images.first

      expect { delete "/profiles/#{profile.id}/profile_images/#{other_image.id}" }
        .not_to change { ActiveStorage::Attachment.exists?(other_image.id) }
      expect(flash[:success]).to be_nil
      expect(response).to redirect_to(edit_profile_path(profile))
    end
  end
end
