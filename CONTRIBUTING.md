# Contributing

Issue reports and pull requests are welcome.

Please test your changes:

```sh
bazel test //...
```

And run the [linters/formatters](.github/workflows/ci.yaml):

```sh
pre-commit run --all-files
```
