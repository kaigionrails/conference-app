namespace :tito do
  # e.g. bin/rails tito:import[2024]
  desc "Import tickets from Tito"
  task :import, [:event_slug] => [:environment] do |t, args|
    if Rails.configuration.x.tito.api_token.nil? || Rails.configuration.x.tito.account_slug.nil?
      abort "Tito API token or account slug is not configured"
    end
    if args.event_slug.nil?
      abort "Event slug is required, e.g. bin/rails tito:import[2025]"
    end
    logger = Logger.new($stdout)

    event = Event.find_by(slug: args.event_slug)
    if event.nil?
      abort "Event not found: #{args.event_slug}"
    end

    client = TitoApiClient.new(event_slug: args.event_slug)
    tickets = client.tickets["tickets"]
    logger.info "Importing #{tickets.size} tickets..."
    tickets.each do |ticket|
      tito_ticket = TitoTicket.find_or_initialize_by(tito_id: ticket["id"])
      tito_ticket.event = event
      tito_ticket.reference = ticket["reference"]
      tito_ticket.unique_url = ticket["unique_url"]
      tito_ticket.state = ticket["state"]
      tito_ticket.slug = ticket["slug"]
      tito_ticket.save! if tito_ticket.new_record? || tito_ticket.changed?
    end
    logger.info "Imported #{tickets.size} tickets."
  end
end
