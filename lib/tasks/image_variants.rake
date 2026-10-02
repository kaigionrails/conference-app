# Generates the image variants pages show, and loads them into CloudFront, so
# that the first visitor to a page does not wait for either:
#
#   kamal app exec --roles=job --reuse 'bin/rails image_variants:backfill'
#   kamal app exec --roles=job --reuse 'bin/rails image_variants:warm'
#
# ONLY=profiles or ONLY=speakers narrows down to one kind of image, and THREADS
# (2 by default) sets how many are handled at once. Both stop with exit status
# 1 if anything failed.
namespace :image_variants do
  targets = {
    "profiles" => {record_type: "Profile", name: "images", variants: %i[icon thumb]},
    "speakers" => {record_type: "Speaker", name: "avatar", variants: %i[thumb]}
  }

  options = lambda do |task_name|
    only = ENV["ONLY"]
    abort "#{task_name}: ONLY must be one of #{targets.keys.join(", ")} (got #{only.inspect})" if only && !targets.key?(only)

    # The main thread's find_each holds a connection, and so does each thread.
    threads = Integer(ENV.fetch("THREADS", "2"))
    pool_size = ActiveRecord::Base.connection_pool.size
    if threads < 1 || threads >= pool_size
      abort "#{task_name}: THREADS must be at least 1 and less than the connection pool (#{pool_size}) (got #{threads})"
    end

    {kinds: only ? [only] : targets.keys, threads:}
  end

  # Yields each attachment with the variant names it needs, in id order.
  # record resolves the named variants; blob: :variant_records tells which
  # are generated without a query each.
  each_attachment = lambda do |kinds, &block|
    kinds.each do |kind|
      target = targets.fetch(kind)
      ActiveStorage::Attachment.where(record_type: target[:record_type], name: target[:name])
        .includes(:record, blob: :variant_records).find_each do |attachment|
          block.call(attachment, target[:variants])
        end
    end
  end

  # VariantWithRecord#processed? is private, so look among the preloaded
  # variant records for this variation.
  generated = lambda do |variant|
    variant.blob.variant_records.any? { |record| record.variation_digest == variant.variation.digest }
  end

  # Runs the block for each attachment's variants on a pool of threads, and
  # counts the names it returns. An attachment is handled by a single thread,
  # so its blob is never shared. An exception is logged and counted as failed,
  # and the rest go on.
  run = lambda do |task_name, kinds:, threads:, &block|
    counts = Concurrent::Map.new
    count = ->(key) { counts.compute_if_absent(key) { Concurrent::AtomicFixnum.new }.increment }
    processed = Concurrent::AtomicFixnum.new
    # A bounded queue, overflowing into the caller, so that find_each does not
    # queue up every attachment before the threads get to them.
    pool = Concurrent::FixedThreadPool.new(threads, max_queue: threads * 4, fallback_policy: :caller_runs)

    Rails.logger.info("#{task_name} started only=#{kinds.join(",")} threads=#{threads}")
    each_attachment.call(kinds) do |attachment, names|
      pool.post do
        Rails.application.executor.wrap do
          names.each do |name|
            count.call(block.call(attachment, name))
          rescue => e
            count.call(:failed)
            Rails.logger.warn("#{task_name} failed attachment_id=#{attachment.id} record=#{attachment.record_type}##{attachment.record_id} " \
              "blob_id=#{attachment.blob_id} variant=#{name} error=#{e.class}: #{e.message}")
          end
        end
        done = processed.increment
        Rails.logger.info("#{task_name} progress processed=#{done}") if done % 100 == 0
      end
    end
    pool.shutdown
    pool.wait_for_termination

    totals = Hash.new(0)
    counts.each_pair { |key, value| totals[key] = value.value }
    totals
  end

  desc "Generate the variants of profile images and speaker avatars that pages show"
  task backfill: :environment do
    task_name = "image_variants:backfill"
    counts = run.call(task_name, **options.call(task_name)) do |attachment, name|
      next :skipped unless attachment.variable?

      variant = attachment.variant(name)
      next :existing if generated.call(variant)

      variant.processed
      :generated
    end

    Rails.logger.info("#{task_name} finished generated=#{counts[:generated]} existing=#{counts[:existing]} " \
      "skipped=#{counts[:skipped]} failed=#{counts[:failed]}")
    exit 1 if counts[:failed] > 0
  end

  desc "Load the generated variants into CloudFront by requesting each once through APPLICATION_URL"
  task warm: :environment do
    require "net/http"

    task_name = "image_variants:warm"
    config = options.call(task_name)
    url_helpers = Rails.application.routes.url_helpers
    hits = ["Hit from cloudfront", "RefreshHit from cloudfront"]

    # One kept-alive connection per thread, opened again after an error.
    fetch = lambda do |url|
      uri = URI.parse(url)
      http = Thread.current[:image_variants_warm_http] ||=
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 30)
      http.request(Net::HTTP::Get.new(uri.path))
    rescue
      http = Thread.current[:image_variants_warm_http]
      http.finish if http&.started?
      Thread.current[:image_variants_warm_http] = nil
      raise
    end

    # The first generated variant, in id order. Requesting one that is not
    # generated yet would make the web container generate it, which is what
    # backfill is for.
    probe = catch(:found) do
      each_attachment.call(config[:kinds]) do |attachment, names|
        next unless attachment.variable?

        variant = names.map { |name| attachment.variant(name) }.find { |candidate| generated.call(candidate) }
        throw :found, variant if variant
      end
      nil
    end
    abort "#{task_name}: no variant is generated yet; run image_variants:backfill first" unless probe

    # The second request is a hit once a CloudFront behavior caches the proxy
    # paths. Without one, warming achieves nothing.
    probe_url = url_helpers.rails_storage_proxy_url(probe)
    fetch.call(probe_url)
    second = fetch.call(probe_url)
    unless hits.include?(second["x-cache"])
      abort "#{task_name}: #{probe_url} was not cached on the second request (status=#{second.code} x-cache=#{second["x-cache"].inspect}); " \
        "is the CloudFront behavior for the Active Storage proxy in place?"
    end

    counts = run.call(task_name, **config) do |attachment, name|
      next :skipped unless attachment.variable?

      variant = attachment.variant(name)
      next :unprocessed unless generated.call(variant)

      response = fetch.call(url_helpers.rails_storage_proxy_url(variant))
      raise "status=#{response.code} x-cache=#{response["x-cache"].inspect}" unless response.code == "200"

      hits.include?(response["x-cache"]) ? :cached : :warmed
    end

    Rails.logger.info("#{task_name} finished cached=#{counts[:cached]} warmed=#{counts[:warmed]} " \
      "unprocessed=#{counts[:unprocessed]} skipped=#{counts[:skipped]} failed=#{counts[:failed]}")
    if counts[:unprocessed] > 0
      Rails.logger.warn("#{task_name} skipped #{counts[:unprocessed]} variants that are not generated yet; run image_variants:backfill first")
    end
    exit 1 if counts[:failed] > 0
  end
end
