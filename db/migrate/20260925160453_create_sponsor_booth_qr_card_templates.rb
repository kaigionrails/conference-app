class CreateSponsorBoothQrCardTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :sponsor_booth_qr_card_templates do |t|
      t.references :event, null: false, foreign_key: true, index: {unique: true}

      t.timestamps
    end
  end
end
