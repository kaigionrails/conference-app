if Rails.env.local?
  require "rbs_rails/rake_task"

  namespace :rbs do
    task setup: %i[clean collection prototype load_routes rbs_rails:all subtract]

    task :clean do
      sh "rm", "-rf", "sig/rbs_rails/"
      sh "rm", "-rf", "sig/prototype/"
      sh "rm", "-rf", ".gem_rbs_collection/"
    end

    task :collection do
      sh "rbs", "collection", "install"
    end

    task :prototype do
      sh "rbs", "prototype", "rb", "--out-dir=sig/prototype", "--base-dir=.", "app"
      sh "rbs", "prototype", "rb", "--out-dir=sig/prototype", "--base-dir=.", "lib"
    end

    task load_routes: :environment do
      # Since Rails 8.0, route drawing has been defered to the first request.
      # This forcedly do route drawing to generate path_helpers via rbs_rails.
      Rails.application.reload_routes_unless_loaded
    end

    task :subtract do
      sh "rbs", "subtract", "--write", "sig/prototype", "sig/rbs_rails"

      prototype_path = Rails.root.join("sig/prototype")
      rbs_rails_path = Rails.root.join("sig/rbs_rails")
      subtrahends = Rails.root.glob("sig/*")
        .reject { |path| path == prototype_path || path == rbs_rails_path }
        .map { |path| "--subtrahend=#{path}" }
      sh "rbs", "subtract", "--write", "sig/prototype", "sig/rbs_rails", *subtrahends
    end

    task :validate do
      sh "rbs", "-Isig", "validate"
    end
  end

  RbsRails::RakeTask.new do |task|
    # If you want to avoid generating RBS for some classes, comment in it.
    # default: nil
    #
    # task.ignore_model_if = -> (klass) { klass == MyClass }

    # If you want to change the rake task namespace, comment in it.
    # default: :rbs_rails
    # task.name = :cool_rbs_rails

    # If you want to change where RBS Rails writes RBSs into, comment in it.
    # default: Rails.root / 'sig/rbs_rails'
    # task.signature_root_dir = Rails.root / 'my_sig/rbs_rails'
  end
end
