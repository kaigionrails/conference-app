require "rails_helper"

RSpec.describe Maintenance::ImportTalksTask do
  let(:event) { FactoryBot.create(:event, slug: "2099") }

  # Tasks take no attributes in new; runs assign them afterwards.
  def task(event_slug)
    described_class.new.tap { |task| task.assign_attributes(event_slug:) }
  end

  describe "validations" do
    it "accepts the slug of an event" do
      expect(task(event.slug)).to be_valid
    end

    it "rejects a slug no event has" do
      expect(task("nope")).to be_invalid
    end
  end

  describe "#process" do
    it "imports the talks of the event" do
      importer = instance_double(TalkImporter, import!: [])
      allow(TalkImporter).to receive(:new).with(event:).and_return(importer)

      task(event.slug).process

      expect(importer).to have_received(:import!)
    end
  end
end
