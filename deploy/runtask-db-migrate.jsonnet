{
  containerOverrides: [
    {
      name: 'app',
      command: ['bundle', 'exec', 'rails', 'db:migrate'],
    },
  ],
}
