require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#message_type_style" do
    context "when message type is success" do
      it "returns success message style" do
        expect(helper.message_type_style("success")).to eq("bg-[#d4edda]")
      end
    end

    context "when message type is alert" do
      it "returns alert message style" do
        expect(helper.message_type_style("alert")).to eq("bg-[#f8d7da]")
      end
    end

    context "when message type is not expected" do
      it "returns an empty string" do
        expect(helper.message_type_style("hoge")).to eq("")
      end
    end
  end
  describe "#page_title" do
    context "when page title is empty string" do
      it "returns only the base title" do
        expect(helper.page_title("")).to eq("ConferenceApp")
      end
    end

    context "when page title is empty string" do
      it "returns the title with base and page title" do
        expect(helper.page_title("Test")).to eq("ConferenceApp - Test")
      end
    end
  end
end
