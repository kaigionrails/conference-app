module Maintenance
  # Imports the talks of an event from db/seeds/<event_slug>.yaml, as bin/rails talks:import does.
  # This is how talks are loaded in production, from the admin pages.
  class ImportTalksTask < MaintenanceTasks::Task
    no_collection

    # @rbs!
    #   attr_accessor event_slug: String?

    attribute :event_slug, :string
    # Checked when the run is created, so a wrong slug is shown before anything is enqueued.
    validates :event_slug, inclusion: {in: ->(_task) { Event.pluck(:slug) }}

    # @rbs return: void
    def process
      TalkImporter.new(event: Event.find_by!(slug: event_slug)).import!
    end
  end
end
