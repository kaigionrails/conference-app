FactoryBot.define do
  factory :sponsor_booth_qr_card_template do
    event

    # Keep the image small for fast specs; 148x210 has exactly the A5 ratio.
    after(:build) do |template|
      png = Vips::Image.black(148, 210, bands: 3).write_to_buffer(".png")
      template.image.attach(io: StringIO.new(png), filename: "template.png", content_type: "image/png")
    end
  end
end
