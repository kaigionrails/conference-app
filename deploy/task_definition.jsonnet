// IF YOU EDIT ENVITORONMENT VARIABLES OR SECRETS, YOU SHOULD ALSO EDIT kaigionrails/terraform/aws/conference-app/*.tf FILES.
{
  parameterStoreArn(name):: std.format('arn:aws:ssm:us-west-2:861452569180:parameter/conference-app/%s', name),


  family: 'conference-app-worker',
  runtimePlatform: { operatingSystemFamily: 'LINUX' },
  taskRoleArn: 'arn:aws:iam::861452569180:role/ConferenceApp',
  executionRoleArn: 'arn:aws:iam::861452569180:role/EcsExecConferenceApp',
  networkMode: 'awsvpc',
  containerDefinitions: [
    {
      name: 'app',
      image: '861452569180.dkr.ecr.us-west-2.amazonaws.com/conference-app:' + std.extVar('IMAGE_SHA'),
      cpu: 0,
      essential: true,
      command: ['bin/jobs', '--recurring_schedule_file=config/recurring.yml'],
      environment: [
        {
          name: 'APPLICATION_URL',
          value: 'https://app.kaigionrails.org',
        },
        {
          name: 'GITHUB_OAUTH_REDIRECT_URI',
          value: 'https://app.kaigionrails.org/auth/github/callback',
        },
        {
          name: 'LANG',
          value: 'en_US.UTF-8',
        },
        {
          name: 'RACK_ENV',
          value: 'production',
        },
        {
          name: 'RAILS_ENV',
          value: 'production',
        },
        {
          name: 'RAILS_LOG_TO_STDOUT',
          value: 'enabled',
        },
        {
          name: 'RAILS_SERVE_STATIC_FILES',
          value: 'enabled',
        },
        {
          name: 'SCOUT_NAME',
          value: 'conference-app',
        },
        {
          name: 'SENTRY_ENV',
          value: 'production',
        },
        {
          name: 'VAPID_SUBJECT_MAILTO',
          value: 'mailto:info@kaigionrails.org',
        },
      ],
      secrets: [
        {
          name: 'CLOUDFLARE_ACCESS_KEY_ID',
          valueFrom: $.parameterStoreArn('CLOUDFLARE_ACCESS_KEY_ID'),
        },
        {
          name: 'CLOUDFLARE_SECRET_ACCESS_KEY',
          valueFrom: $.parameterStoreArn('CLOUDFLARE_SECRET_ACCESS_KEY'),
        },
        {
          name: 'CLOUDFLARE_R2_BUCKET_NAME',
          valueFrom: $.parameterStoreArn('CLOUDFLARE_R2_BUCKET_NAME'),
        },
        {
          name: 'CLOUDFLARE_R2_ENDPOINT',
          valueFrom: $.parameterStoreArn('CLOUDFLARE_R2_ENDPOINT'),
        },
        {
          name: 'DATABASE_URL',
          valueFrom: $.parameterStoreArn('DATABASE_URL'),
        },
        {
          name: 'GITHUB_APP_ID',
          valueFrom: $.parameterStoreArn('GITHUB_APP_ID'),
        },
        {
          name: 'GITHUB_KEY',
          valueFrom: $.parameterStoreArn('GITHUB_KEY'),
        },
        {
          name: 'GITHUB_PRIVATE_KEY',
          valueFrom: $.parameterStoreArn('GITHUB_PRIVATE_KEY'),
        },
        {
          name: 'GITHUB_SECRET',
          valueFrom: $.parameterStoreArn('GITHUB_SECRET'),
        },
        {
          name: 'REDIS_TLS_URL',
          valueFrom: $.parameterStoreArn('REDIS_TLS_URL'),
        },
        {
          name: 'REDIS_URL',
          valueFrom: $.parameterStoreArn('REDIS_URL'),
        },
        {
          name: 'SCOUT_KEY',
          valueFrom: $.parameterStoreArn('SCOUT_KEY'),
        },
        {
          name: 'SECRET_KEY_BASE',
          valueFrom: $.parameterStoreArn('SECRET_KEY_BASE'),
        },
        {
          name: 'SENTRY_DSN',
          valueFrom: $.parameterStoreArn('SENTRY_DSN'),
        },
        {
          name: 'VAPID_PRIVATE_KEY',
          valueFrom: $.parameterStoreArn('VAPID_PRIVATE_KEY'),
        },
        {
          name: 'VAPID_PUBLIC_KEY',
          valueFrom: $.parameterStoreArn('VAPID_PUBLIC_KEY'),
        },
      ],
      logConfiguration: {
        logDriver: 'awslogs',
        options: {
          'awslogs-group': '/ecs/conference-app-worker',
          'awslogs-region': 'us-west-2',
          'awslogs-stream-prefix': 'ecs',
        },
      },
    },
  ],
  cpu: '256',
  memory: '512',
  tags: [
    {
      key: 'Project',
      value: 'kaigionrails',
    },
  ],
}
