{
  region: 'us-west-2',
  cluster: 'kor-usw2-fargate',
  service: 'conference-app-worker',
  service_definition: 'service_definition.jsonnet',
  task_definition: 'task_definition.jsonnet',
  timeout: '5m',
}
