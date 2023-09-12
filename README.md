<p align="center">
  <img alt="crimson-logo" src="assets/crimson_banner.png" width="700">
  <h3 align="center">Crimson</h3>
  <p align="center">Crystal version management made easy</p>
</p>

## Installation

### MacOS

```
brew tap crimson-crystal/distribution https://github.com/crimson-crystal/distribution
brew install crimson
```

### Windows

```
scoop bucket add crimson https://github.com/crimson-crystal/distribution
scoop install crimson
```

### From Release

See the [releases page](https://github.com/crimson-crystal/crimson/releases) for available packaged binaries.

#### Linux

```sh
curl -L https://github.com/crimson-crystal/crimson/releases/download/nightly/crimson-nightly-linux-x86_64.tar.gz -o crimson.tar.gz
tar -xvf crimson.tar.gz -C /usr/local/bin
```

#### Windows (PowerShell)

```ps1
Invoke-WebRequest "https://github.com/crimson-crystal/crimson/releases/download/nightly/crimson-nightly-windows-x86_64-msvc.zip" -OutFile crimson.zip
Expand-Archive .\crimson.zip .
```

> **Note**
> Make sure to add the `crimson.exe` and `crimson.pdb` files to a directory in `PATH`.

### From Source

[Crystal](https://crystal-lang.org) version 1.9.2 or higher is required to build Crimson. Make sure to add the `bin/` directory to `PATH` or move the Crimson binaries to a directory in `PATH`.

```sh
git clone https://github.com/crimson-crystal/crimson
cd crimson
shards build
```

## Usage

To get started, simply run `crimson setup`. This will setup the necessary configuration files and directories for Crimson, update your system to make the `crystal` and `shards` executables available and prompt you to install the necessary build dependencies for Crystal. You can bypass the prompts by including the `-y`/`--yes` flag, or skip dependency installation by including the `-s`/`--skip-dependencies` flag.

> **Note**
> Crystal's dependencies are not typically readily available on most systems so you will need to install them manually if you choose to skip them in the command.

Next, install Crystal using `crimson install` (or `crimson in`). By default this will install the latest available version unless you specify one (for example, `crimson install 1.9.2`). You can install any Crystal version that is available on the [Crystal GitHub releases page](https://github.com/crystal-lang/crystal/releases). This unfortunately means that nightly builds cannot be installed via Crimson yet.

Finally, run the `crimson switch <version>` command to make that version of Crystal available on your system. You can also do this automatically by including the `-s`/`--switch` flag in `crimson install`. Now, try `crystal version`! To put this in perspective, you just setup and installed Crystal with 3 simple commands:

```sh
crimson setup
crimson install 1.9.2
crimson switch 1.9.2
```

### Aliases

Versions can be aliased to make using them easier: run `crimson alias <name> <version>` to set an alias for a specific version (for example, `crimson alias dev 1.9.2`). You can view all aliases with `crimson alias` and delete an alias with `crimson alias -d <name>`. Aliases can also be set automatically by including the `-a`/`--alias` flag.

### Switching

You can switch between Crystal versions using `crimson switch <version>` (or `crimson use`). If the version you wish to switch to has an alias, you can use that instead (for example, `crimson switch dev`). Versions can also be switched to automatically in the install command by including the `-s`/`--switch` flag. If you want to temporarily remove the current version from your system (for example, if you wanted to revert to a local install of Crystal) you can do so with `crimson switch -d`. This doesn't uninstall the Crystal version entirely, meaning you can easily switch back to it at any time.

### Defaults

What if you frequently install or switch versions and need a default available? You can set one using `crimson default <version>`. This also supports using aliases in place of the version.

But how exactly does it work? Lets say you have `1.9.2` as default and you're working with version `1.7.3` but no longer need it, so you remove it. Crimson will automatically switch back to the configured default so that you still have a version of Crystal available on your system.

You can also easily switch between your current and default version using `crimson switch .` which will set the former to the latter. Defaults can be removed using `crimson default -d`.

### Removing

Removing Crystal versions is as simple as `crimson remove <version>` (or `crimson rm`), and you can use the alias in place of the version.

### Useful Tricks

All the above commands can be combined via flags in the install command:

```sh
crimson install -sa dev 1.9.2
#                ^^
#                /\
#     switch to /  set the alias to "dev"
#  this version

crimson install -fd
# install the latest version and make it the default

crimson install -a legacy -ds 1.0.0
#                ^         ^^
#  set the alias /         |\ switch to this version
#  to "legacy"             \
#                           make it the default
```

### Side Notes

Crimson caches available versions locally from the [Crystal API](https://crystal-lang.org/api/versions.json) so if newer releases don't appear as available via Crimson, run the install command with the `-f`/`--fetch` flag which will force-check the API and cache newer versions. If that doesn't work, check the API as it's likely it hasn't been updated to include the newer versions yet.

## Contributing

1. Fork it (<https://github.com/crimson-crystal/crimson/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Devonte W](https://github.com/devnote-dev) - creator and maintainer

This repository is managed under the Mozilla Public License v2.

© 2023 devnote-dev
