{
  publicSubnets:: ['subnet-0a12bdf9fec833793', 'subnet-01c36fdbe2d472874'],  // c, d

  launchType: 'FARGATE',
  platformFamily: 'LINUX',
  platformVersion: 'LATEST',
  serviceName: 'conference-app-worker',
  deploymentConfiguration: {
    maximumPercent: 100,
    minimumHealthyPercent: 0,
  },
  tags: [
    { key: 'Project', value: 'kaigionrails' },
  ],
  enableECSManagedTags: true,
  enableExecuteCommand: true,
  networkConfiguration: {
    awsvpcConfiguration: {
      subnets: $.publicSubnets,
      securityGroups: [
        'sg-0a7b02c6f8ee18e6c',
      ],
      assignPublicIp: 'ENABLED',
    },
  },
}
