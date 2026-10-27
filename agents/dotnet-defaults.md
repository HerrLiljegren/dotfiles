# .NET solution and project defaults

For new .NET solutions unless explicitly requested otherwise:

- Put shared MSBuild settings in `build/DotNet.props` and test settings in
  `build/DotNet.Tests.props`, imported through root `Directory.Build.props`.
- Use root `Directory.Packages.props` with
  `ManagePackageVersionsCentrally=true`. Keep versions out of
  `PackageReference` entries.
- Default tests to TUnit on Microsoft.Testing.Platform. Configure the runner in
  `global.json`.
- Name projects by role without a product prefix: `Cli.csproj`,
  `Application.csproj`, and `Cli.Tests.csproj`.
