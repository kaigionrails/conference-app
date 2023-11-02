if Rails.env.development? || Rails.env.test?
  require 'rbs_rails/rake_task'

  namespace :rbs do
    task setup: %i[clean collection prototype rbs_rails:all subtract]

    task :clean do
      sh 'rm', '-rf', 'sig/rbs_rails/'
      sh 'rm', '-rf', 'sig/prototype/'
      sh 'rm', '-rf', '.gem_rbs_collection/'
    end

    task :collection do
      sh 'rbs', 'collection', 'install'
    end

    task :prototype do
      sh 'rbs', 'prototype', 'rb', '--out-dir=sig/prototype', '--base-dir=.', 'app/models'
      sh 'rbs', 'prototype', 'rb', '--out-dir=sig/prototype', '--base-dir=.', 'app/jobs'
      sh 'rbs', 'prototype', 'rb', '--out-dir=sig/prototype', '--base-dir=.', 'app/decorators'
      sh 'rbs', 'prototype', 'rb', '--out-dir=sig/prototype', '--base-dir=.', 'app/helpers'
      sh 'rbs', 'prototype', 'rb', '--out-dir=sig/prototype', '--base-dir=.', 'app/channels'
      sh 'rbs', 'prototype', 'rb', '--out-dir=sig/prototype', '--base-dir=.', 'lib'
    end

    task :subtract do
      sh 'rbs', 'subtract', '--write', 'sig/prototype', 'sig/rbs_rails'

      prototype_path = Rails.root.join('sig/prototype')
      rbs_rails_path = Rails.root.join('sig/rbs_rails')
      subtrahends = Rails.root.glob('sig/*')
        .reject { |path| path == prototype_path || path == rbs_rails_path }
        .map { |path| "--subtrahend=#{path}" }
      sh 'rbs', 'subtract', '--write', 'sig/prototype', 'sig/rbs_rails', *subtrahends
    end

    task :validate do
      sh 'rbs', '-Isig', 'validate', '--silent'
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
