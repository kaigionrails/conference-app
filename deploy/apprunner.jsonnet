{
  ServiceArn: 'arn:aws:apprunner:us-west-2:861452569180:service/conference-app/37cc4e1e45894229965d668879123b40',
  SourceConfiguration: {
    ImageRepository: {
      ImageIdentifier: '861452569180.dkr.ecr.us-west-2.amazonaws.com/conference-app:' + std.extVar('IMAGE_SHA'),
      ImageRepositoryType: 'ECR',
    },
  },
}
