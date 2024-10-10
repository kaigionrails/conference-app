{
  ServiceArn: 'arn:aws:apprunner:us-west-2:861452569180:service/conference-app-staging/acfd5f3cb79044cf96a2d70c481da77a',
  SourceConfiguration: {
    ImageRepository: {
      ImageIdentifier: '861452569180.dkr.ecr.us-west-2.amazonaws.com/conference-app:' + std.extVar('IMAGE_SHA'),
      ImageRepositoryType: 'ECR',
    },
  },
}
