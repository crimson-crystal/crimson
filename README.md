<p align="center">
  <picture>
    <source
      media="(prefers-color-scheme: dark)"
      srcset="assets/crimson_banner_light.png"
    />
    <img
      alt="logo"
      src="assets/crimson_banner_dark.png"
      width="720px"
    />
  </picture>
  <h3 align="center">Crimson</h3>
  <p align="center">Crystal version management made easy</p>
</p>

## Installation

<!-- ### MacOS

```
brew tap crimson-crystal/distribution https://github.com/crimson-crystal/distribution
brew install crimson
``` -->

<!-- ### Linux

```sh
# Debian/Ubuntu
apt install crimson

# Alpine
apk add crimson

# Arch
pacman -S crimson
``` -->

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

> [!IMPORTANT]
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

> [!NOTE]
> Crystal's dependencies are not typically readily available on most systems so you will need to install them manually if you choose to skip them in the command.

Next, install Crystal using `crimson install` (or `crimson in`). By default this will install the latest available version unless you specify one (for example, `crimson install 1.9.2`). You can install any Crystal version that is available on the [Crystal GitHub releases page](https://github.com/crystal-lang/crystal/releases). This unfortunately means that nightly builds cannot be installed via Crimson yet.

Finally, run the `crimson switch <version>` command to make that version of Crystal available on your system. You can also do this automatically by including the `-s`/`--switch` flag in `crimson install`. Now, try `crystal version`! To put this in perspective, you just setup and installed Crystal with 3 simple commands:

```sh
❯ crimson setup
Checking dependencies
Checking additional dependencies
No additional dependencies for this platform

❯ crimson install 1.9.2
Installing Crystal version: 1.9.2
Downloading sources...
Unpacking archive to destination...
1647 files unpacked (54.0MiB)
Cleaning up processes...

❯ crimson switch 1.9.2
```

### Aliases

Versions can be aliased to make using them easier: run `crimson alias <name> <version>` to set an alias for a specific version (for example, `crimson alias dev 1.9.2`). You can view all aliases with `crimson alias` and delete an alias with `crimson alias -d <name>`. Aliases can also be set automatically by including the `-a`/`--alias` flag.

### Switching

You can switch between Crystal versions using `crimson switch <version>` (or `crimson use`). If the version you wish to switch to has an alias, you can use that instead (for example, `crimson switch dev`). Versions can also be switched to automatically in the install command by including the `-s`/`--switch` flag. If you want to temporarily remove the current version from your system (for example, if you wanted to revert to a local install of Crystal) you can do so with `crimson switch -d`. This doesn't uninstall the Crystal version entirely, meaning you can easily switch back to it at any time.

### Defaults

What if you frequently install or switch versions and need a default available? You can set one using `crimson default <version>`. This also supports using aliases in place of the version.

But how exactly does it work? Lets say you have `1.9.2` as default and you're working with version `1.7.3` but no longer need it, so you remove it. Crimson will automatically switch back to the configured default so that you still have a version of Crystal available on your system.

You can also easily switch between your current and default version using `crimson switch .` which will set the former to the latter. Defaults can be removed using `crimson default -d`.

### Importing

If you have a local Crystal compiler environment, you can import it into Crimson's environment using `crimson import`. This command has a few requirements:

- The `bin/`, `lib/` and `src/` directories must be present
- Crystal must already be compiled and its binaries readily available in the `bin/` directory

To ensure Crimson's cross-platform compatibility and platform-specific system requirements, Crystal cannot be built using this command. The install version is obtained from the compiler during the import process. If that version is already installed, the command will fail. To work around this you can specify the `-R`/`--rename` flag with a version name to be imported under.

By default, local compiler sources are copied into Crimson's environment. If you want to update source files without having to re-import the compiler environment, you can specify the `--link` flag which connects the local compiler environment to Crimson's environment.

> [!NOTE]
> On Windows, using `--link` with `--switch` does not always update instantly due to how CMD/PowerShell handles symlinks. Running `crimson switch <import_version>` will fix this.

Just like normal installs, `import` supports aliases, switching and setting the version as default.

### Testing

Crimson allows you to iterate over installed versions using a test command as a condition. For example, `crimson test -- shards build` will test `shards build` on all installed versions. By default the versions are tested in descending order but can be ran in ascending or random order by specifying the `--order` flag.

If you only want to test a subset of versions then you can specify the `--from` flag with a version to start from and/or the `--to` flag with a version to stop at. Additionally, you can specify versions to include or exclude on top of this subset using the `-i`/`--include` and `-e`/`--exclude` flags respectively, which support multiple arguments (for example, `crimson test -e master -e dev ...`).

```crystal
# test.cr

p ([] of Int32).insert_all(0, [1, 2, 3])
```

```sh
❯ crimson test -e dev --from latest --to 1.12.2 -- crystal build test.cr --no-codegen
1.13.2 • Passed
1.13.1 • Passed
1.13.0 • Passed
1.12.2 • Failed
┃ Showing last frame. Use --error-trace for full trace.
┃
┃ In test.cr:3:17
┃
┃  3 | p ([] of Int32).insert_all(0, [1, 2, 3])
┃                      ^---------
┃ Error: undefined method 'insert_all' for Array(Int32)
```

### Removing

Removing Crystal versions is as simple as `crimson remove <version>` (or `crimson rm`), and you can use the alias in place of the version.

### Side Notes

Crimson caches available versions locally from the [Crystal API](https://crystal-lang.org/api/versions.json) so if newer releases don't appear as available via Crimson, run the install command with the `-f`/`--fetch` flag which will force-check the API and cache newer versions. If that doesn't work, check the API as it's likely it hasn't been updated to include the newer versions yet.

## Motivation

Crimson is designed to be like any other application versioning manager using standardised design patterns to ensure consistency and flexibility. It _is_ intended for people that work with multiple versions of Crystal and/or need to ensure backwards compatibility for their projects. It is _not_ intended to be a replacement for system package managers or other Crystal distribution sources (although you can use it for that if you wish).

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
