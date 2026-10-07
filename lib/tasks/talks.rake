namespace :talks do
  # e.g. bin/rails talks:import[2026]
  # In production, Maintenance::ImportTalksTask on the admin pages does the same.
  desc "Import talks and speakers of an event from db/seeds/<event_slug>.yaml"
  task :import, [:event_slug] => [:environment] do |t, args|
    if args.event_slug.nil?
      abort "Event slug is required, e.g. bin/rails talks:import[2026]"
    end

    event = Event.find_by(slug: args.event_slug)
    if event.nil?
      abort "Event not found: #{args.event_slug}"
    end

    talks = TalkImporter.new(event:).import!
    puts "Imported #{talks.size} talks into #{event.name}"
  end
end
