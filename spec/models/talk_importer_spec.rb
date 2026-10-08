require "rails_helper"

RSpec.describe TalkImporter do
  let(:event) { FactoryBot.create(:event, slug: "2099") }
  let(:sample_png) { Rails.root.join("spec/assets/sample.png") }
  let(:path) { @dir.join("talks.yaml") }
  let(:avatar_dir) { @dir.join("avatars") }

  # Avatars are uploaded within import!, so the files have to outlive the call.
  around do |example|
    Dir.mktmpdir do |dir|
      @dir = Pathname(dir)
      example.run
    end
  end

  def speaker_data(slug, **attributes)
    {name: slug.capitalize, slug:, github_username: slug, gravatar_hash: nil, bio: "I am #{slug}."}.merge(attributes)
  end

  def talk_data(title, speakers: [speaker_data("alice")], **attributes)
    {
      title:,
      abstract: "About #{title}.",
      start_at: Time.new(2099, 10, 16, 11, 0, 0, "+09:00"),
      duration_minutes: 30,
      track: "Magenta Hall",
      speakers:
    }.merge(attributes)
  end

  def import(talks, tracks: nil)
    data = {talks:}
    data[:tracks] = tracks if tracks
    path.write(YAML.dump(data))
    described_class.new(event:, path:, avatar_dir:).import!
  end

  def put_avatar(filename)
    avatar_dir.mkpath
    FileUtils.cp(sample_png, avatar_dir.join(filename))
  end

  def counts
    [Talk.count, Speaker.count, ActiveStorage::Blob.count]
  end

  describe "#import!" do
    it "creates the talks and the speakers of the event" do
      talks = import([
        talk_data("First"),
        talk_data("Second", speakers: [speaker_data("bob"), speaker_data("carol")], track: "Lime Hall")
      ])

      expect(talks).to eq(event.talks.order(:id).to_a)
      expect(talks.map(&:title)).to eq(["First", "Second"])
      expect(talks.first).to have_attributes(
        abstract: "About First.",
        start_at: Time.zone.parse("2099-10-16 11:00:00 +0900"),
        duration_minutes: 30,
        track: "Magenta Hall"
      )
      expect(talks.first.speakers.map(&:slug)).to eq(["alice"])
      expect(talks.second.speakers.map(&:slug)).to contain_exactly("bob", "carol")
      expect(Speaker.find_by!(slug: "alice")).to have_attributes(name: "Alice", github_username: "alice", bio: "I am alice.")
    end

    it "uses one speaker for the talks the speaker gives" do
      import([talk_data("First"), talk_data("Second")])

      expect(Speaker.where(slug: "alice").count).to eq(1)
      expect(Speaker.find_by!(slug: "alice").talks.count).to eq(2)
    end

    it "overwrites the attributes of an existing speaker with the file" do
      speaker = FactoryBot.create(:speaker, slug: "alice", name: "Old name", bio: "Old bio.")

      expect { import([talk_data("First")]) }.not_to change { Speaker.count }
      expect(speaker.reload).to have_attributes(name: "Alice", bio: "I am alice.")
    end

    it "accepts any track when the file has no tracks" do
      talks = import([talk_data("First", track: "Anywhere")])

      expect(talks.first.track).to eq("Anywhere")
    end

    it "accepts the tracks the file lists" do
      talks = import([talk_data("First", track: "Lime Hall")], tracks: ["Magenta Hall", "Lime Hall"])

      expect(talks.first.track).to eq("Lime Hall")
    end

    describe "avatars" do
      it "attaches the file named after the speaker" do
        put_avatar("alice.png")

        import([talk_data("First")])

        avatar = Speaker.find_by!(slug: "alice").avatar
        expect(avatar).to be_attached
        expect(avatar.filename.to_s).to eq("alice.png")
      end

      it "leaves a speaker without an avatar when there is no file" do
        import([talk_data("First")])

        expect(Speaker.find_by!(slug: "alice").avatar).not_to be_attached
      end

      it "keeps the avatar a speaker already has" do
        speaker = FactoryBot.create(:speaker, slug: "alice")
        speaker.avatar.attach(ActiveStorage::Blob.create_and_upload!(io: sample_png.open("rb"), filename: "old.png"))
        put_avatar("alice.png")

        expect { import([talk_data("First")]) }.not_to change { ActiveStorage::Blob.count }
        expect(speaker.reload.avatar.filename.to_s).to eq("old.png")
      end

      it "fetches avatar_url in preference to the file" do
        put_avatar("alice.jpg")
        request = stub_request(:get, "https://kaigionrails.example.invalid/images/keynote/a.png")
          .to_return(body: sample_png.binread, headers: {"Content-Type" => "image/png"})

        import([talk_data("First", speakers: [speaker_data("alice", avatar_url: "https://kaigionrails.example.invalid/images/keynote/a.png")])])

        expect(request).to have_been_requested.once
        avatar = Speaker.find_by!(slug: "alice").avatar
        expect(avatar.filename.to_s).to eq("alice.png")
        expect(avatar.content_type).to eq("image/png")
      end

      it "names the avatar after the content when the URL has no extension" do
        stub_request(:get, "https://kaigionrails.example.invalid/avatars/alice")
          .to_return(body: sample_png.binread, headers: {"Content-Type" => "image/png"})

        import([talk_data("First", speakers: [speaker_data("alice", avatar_url: "https://kaigionrails.example.invalid/avatars/alice")])])

        expect(Speaker.find_by!(slug: "alice").avatar.filename.to_s).to eq("alice.png")
      end

      it "fails without changes when fetching an avatar fails" do
        # bob's avatar is uploaded before alice's fails, and has to be removed.
        put_avatar("bob.png")
        stub_request(:get, "https://kaigionrails.example.invalid/alice.png").to_return(status: 404)

        expect {
          expect {
            import([
              talk_data("First", speakers: [speaker_data("bob")]),
              talk_data("Second", speakers: [speaker_data("alice", avatar_url: "https://kaigionrails.example.invalid/alice.png")])
            ])
          }.to raise_error(OpenURI::HTTPError)
        }.not_to change { counts }
      end

      it "fails without changes when avatar_url is not an image" do
        stub_request(:get, "https://kaigionrails.example.invalid/alice.png")
          .to_return(body: "<!DOCTYPE html><html><body>Not Found</body></html>", headers: {"Content-Type" => "text/html"})

        expect {
          expect {
            import([talk_data("First", speakers: [speaker_data("alice", avatar_url: "https://kaigionrails.example.invalid/alice.png")])])
          }.to raise_error(StandardError, %(Avatar of speaker "alice" at https://kaigionrails.example.invalid/alice.png is not an image (text/html)))
        }.not_to change { counts }
      end
    end

    context "when the event already has talks" do
      before { FactoryBot.create(:talk, event:) }

      it "fails without uploading avatars" do
        put_avatar("alice.png")

        expect {
          expect { import([talk_data("First")]) }.to raise_error(StandardError, "Talks of event 2099 are already imported")
        }.not_to change { counts }
      end
    end

    context "when a talk cannot be saved" do
      it "rolls back the other talks and removes the uploaded avatars" do
        put_avatar("alice.png")

        expect {
          expect {
            import([talk_data("First"), talk_data(nil, speakers: [speaker_data("bob")])])
          }.to raise_error(ActiveRecord::NotNullViolation)
        }.not_to change { counts }
      end
    end

    context "when the file has problems" do
      it "fails on a track not in tracks" do
        expect {
          expect {
            import([talk_data("First", track: "Hell Red")], tracks: ["Magenta Hall", "Lime Hall"])
          }.to raise_error(StandardError, /talks\[0\] "First": track "Hell Red" is not in tracks \(Magenta Hall, Lime Hall\)/)
        }.not_to change { counts }
      end

      it "fails on a talk without speakers" do
        expect {
          expect { import([talk_data("First", speakers: [])]) }.to raise_error(StandardError, /talks\[0\] "First": no speakers/)
        }.not_to change { counts }
      end

      it "fails on a speaker without slug" do
        expect {
          expect {
            import([talk_data("First", speakers: [speaker_data("alice", slug: ""), speaker_data("bob", name: "Bob", slug: nil)])])
          }.to raise_error(StandardError, /talks\[0\] "First": speaker "Alice" has no slug; talks\[0\] "First": speaker "Bob" has no slug/)
        }.not_to change { counts }
      end

      it "fails on avatar_url that is not https" do
        expect {
          expect {
            import([talk_data("First", speakers: [speaker_data("alice", avatar_url: "http://kaigionrails.example.invalid/alice.png")])])
          }.to raise_error(StandardError, %r{talks\[0\] "First": speaker "alice" avatar_url "http://kaigionrails.example.invalid/alice.png" is not an https URL})
        }.not_to change { counts }
      end

      it "lists all the problems at once" do
        put_avatar("alice.png")

        expect {
          expect {
            import(
              [talk_data("First", track: "Hell Red"), talk_data("Second", speakers: [])],
              tracks: ["Magenta Hall", "Lime Hall"]
            )
          }.to raise_error(
            StandardError,
            %(Invalid talks in #{path.relative_path_from(Rails.root)}: talks[0] "First": track "Hell Red" is not in tracks (Magenta Hall, Lime Hall); talks[1] "Second": no speakers)
          )
        }.not_to change { counts }
      end
    end
  end
end
