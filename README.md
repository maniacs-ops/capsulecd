# CapsuleCD

[![Circle CI](https://circleci.com/gh/AnalogJ/capsulecd.svg?style=shield)](https://circleci.com/gh/AnalogJ/capsulecd)
[![Coverage Status](https://coveralls.io/repos/github/AnalogJ/capsulecd/badge.svg)](https://coveralls.io/github/AnalogJ/capsulecd)
[![GitHub license](https://img.shields.io/github/license/AnalogJ/capsulecd.svg)](https://github.com/AnalogJ/capsulecd/blob/master/LICENSE)
[![Gem](https://img.shields.io/gem/dt/capsulecd.svg)](https://rubygems.org/gems/capsulecd)
[![Gem](https://img.shields.io/gem/v/capsulecd.svg)](https://rubygems.org/gems/capsulecd)
[![Docker Pulls](https://img.shields.io/docker/pulls/analogj/capsulecd.svg)](https://hub.docker.com/r/analogj/capsulecd)
[![Flattr this git repo](https://button.flattr.com/flattr-badge-large.png)](https://flattr.com/submit/auto?fid=analogj&url=https%3A%2F%2Fgithub.com%2FAnalogJ%2Fcapsulecd&title=CapsuleCD&language=Ruby&tags=github&category=software)

<!-- 
[![Gemnasium](https://img.shields.io/gemnasium/analogj/capsulecd.svg)]()
-->

CapsuleCD is a generic Continuous Delivery pipeline for versioned artifacts and libraries written in any language. 
It's goal is to bring automation to the packaging and deployment stage of your library release cycle.
CapsuleCD is incredibly flexible, and works best when implemented side-by-side with a CI pipeline.

A short list of the features...

* Supports libraries written in any language. Has built-in support for 
	* Chef Cookbooks
	* Python Pip
	* NodeJS Npm Packages
	* Ruby Gems
	* Vanilla Javascript Bower/Npm Packages
* Highly configurable
* Follows language/library best practices. Including things like:
	* automatically bumping the semvar version number
	* regenerating any `*.lock` files/ shrinkwrap files with new version
	* creating any recommended files (eg. `.gitignore`) 
	* validates all dependencies exist (by vendoring locally)
	* running unit tests
	* source minification
	* linting library syntax
	* generating code coverage reports
	* updating changelog
	* uploading versioned artifact to community hosting service (rubygems/supermarket/pypi/etc)
	* creating a new git tag 
	* pushing changes back to source control (github)
	* creating a new release in source control (github) and attaching any common artifacts
	
## Links

* Source: <http://github.com/AnalogJ/capsulecd>
* Bugs:   <http://github.com/AnalogJ/capsulecd/issues>

# Introduction

## What is CapsuleCD

CapsuleCD is a generic Continuous Delivery pipeline for versioned artifacts and libraries written in any language. 
It's goal is to bring automation to the packaging and deployment stage of your library release cycle.
It automates away all the common steps required when creating a new version of your library.

## Why use CapsuleCD
At first glance, it seems simple to publish a new library version. Just bump the version number and publish, right?
Well, not always:

- If you're library includes a Gemfile.lock, Berksfile.lock or other common lock files, you'll need to regenerate them as the old version number is embedded inside. 
- Everyone runs their library unit tests before creating a new release (right?!), but what about validating that your [library dependencies exist](http://www.theregister.co.uk/2016/03/23/npm_left_pad_chaos/) (maybe in your Company's private repo)?
- How about linting your source, to ensure that it follows common/team conventions? 
- Who owns the gem? Is there one developer who has the credentials to push to RubyGems.org? Are they still on your team/on vacation? 
- Did you remember to tag your source when the new version was created (making it easy to determine what's changed between versions?)
- Did you update your changelog?

CapsuleCD handles all of that (and more!) for you. It pretty much guarantees that your library will have proper and consistent releases every time. 
CapsuleCD is well structured and fully tested, unlike the release scripts you've manually cobbled together for each library and language. It can be customized as needed without rewriting from scratch.
The best part is that CapsuleCD uses CapsuleCD to automate its releases. We [dogfood](https://en.wikipedia.org/wiki/Eating_your_own_dog_food) it so we're the first ones to find any issues with a new release. 

## How do I start?
You can use CapsuleCD to automate creating a new release from a pull request __or__ from the latest code on your default branch.

### Automated pull request processing:

Here's how to use __docker__ to merge a pull request to your Ruby library

    CAPSULE_SOURCE_GITHUB_ACCESS_TOKEN=123456789ABCDEF \
    CAPSULE_RUNNER_REPO_FULL_NAME=AnalogJ/gem_analogj_test \
    CAPSULE_RUNNER_PULL_REQUEST=4 \
    CAPSULE_RUBYGEMS_API_KEY=ASDF12345F \
    docker run AnalogJ/capsulecd:ruby capsulecd start --source github --package_type ruby

Or you could __install__ and call CapsuleCD directly to merge a pull request to your Python library:

	gem install capsulecd
	CAPSULE_SOURCE_GITHUB_ACCESS_TOKEN=123456789ABCDEF \
	CAPSULE_RUNNER_REPO_FULL_NAME=AnalogJ/pip_analogj_test \
	CAPSULE_RUNNER_PULL_REQUEST=2 \
	CAPSULE_PYPI_USERNAME=AnalogJ \
	CAPSULE_PYPI_PASSWORD=mysupersecurepassword \
	capsulecd start --source github --package_type python
	
### Creating a branch release

	TODO: add documentation on how to create a release from the master branch without a pull request. Specify the env variables required. 
	
# Engine
Every package type is mapped to an engine class which inherits from a `BaseEngine` class, ie `PythonEngine`, `NodeEngine`, `RubyEngine` etc. 
Every source type is mapped to a source module, ie `GithubSource`. When CapsuleCD starts, it initializes the specified Engine, and loads the correct Source module.
Then it begins processing your source code step by step.

Step | Description
------------ | ------------ 
source_configure | This will initialize the source client, ensuring that we can authenticate with the git server
runner_retrieve_payload | If a Pull Request # is specified, the payload is retrieved from Source api, otherwise the repo default branch HEAD info is retrived.
source_process_pull_request_payload __or__ source_process_push_payload | Depending on the retrieve_payload step, the merged pull request is cloned, or the default branch is cloned locally
build_step | Code is built, which includes adding any missing files/default structure, compilation, version bumping, etc.
test_step | Download package dependencies, run the package test runner(s) (eg. npm test, rake test, kitchen test, tox)
package_step | Commit any local changes and create a git tag. Nothing should be pushed to remote repository
release_step | Push the release to the package repository (ie. npm, chef supermarket, rubygems)
source_release | Push the merged, tested and version updated code up to the source code repository. Also do any source specific releases (github release, asset uploading, etc)

# Configuration
Specifying your `GITHUB_ACCESS_TOKEN` and `PYPI_PASSWORD` via an environmental variable might make sense, but do you 
really want to specify the `PYPI_USERNAME`, `REPO_FULL_NAME` each time? Probably not. 

CapsuleCD has you covered. We support a global YAML configuration file (that can be specified using the `--config-file` flag), and a repo specific YAML configuration file stored as `capsule.yml` inside the repo itself.

## Setting Inheritance/Overrides
CapsuleCD settings are determined by loading configuration in the following order (where the last value specified is used)

- system YAML config file (`--config-file`)
- repo YAML config file (`capsule.yml`)
- environmental variables (setting in capital letters and prefixed with `CAPSULE_`)

## Configuration Settings

Setting | System Config | Repo Config | Notes
------------ | ------------- | ------------- | -------------
package_type | No | No | Must be set by `--package-type` flag
source | No | No | Must be set by `--source` flag
runner | No | No | Must be set by `--runner` flag
dry_run | No | No | Must be set by `--[no]-dry-run` flag
source_git_parent_path | Yes | No | Specifies the location where the git repo will be cloned, defaults to tmp directory
source_github_api_endpoint | Yes | No | Specifies the Github api endpoint to use (for use with Enterprise Github)
source_github_web_endpoint | Yes | No | Specifies the Github web endpoint to use (for use with Enterprise Github)
source_github_access_token | Yes | No | Specifies the access token to use when cloning from and committing to Github
runner_pull_request | Yes | No | Specifies the repo pull request number to clone from  Github
runner_repo_full_name | Yes | No | Specifies the repo name to clone from Github
chef_supermarket_username | Yes | Yes | Specifies the Chef Supermarket username to use when creating public release for Chef cookbook
chef_supermarket_key | Yes | Yes | Specifies the Base64 encoded Chef Supermarket private key to use when creating public release for Chef cookbook
chef_supermarket_type | Yes | Yes | Specifies the Chef Supermarket cookbook type to use when creating public release for Chef cookbook
npm_auth_token | Yes | Yes | Specifies the NPM auth to use when creating public release for NPM package
pypi_username | Yes | Yes | Specifies the PYPI username to use when creating public release for Pypi package
pypi_password | Yes | Yes | Specifies the PYPI password to use when creating public release for Pypi package
engine_disable_test | Yes | Yes | Disables test_step before releasing package
engine_disable_minification | Yes | Yes | Disables source minification (if applicable) before releasing package
engine_disable_lint | Yes | Yes | Disables source linting before releasing package
engine_cmd_test | Yes | Yes | Specifies the test command to before releasing package
engine_cmd_minification | Yes | Yes | Specifies the minification command to before releasing package
engine_cmd_lint | Yes | Yes | Specifies the lint command to before releasing package
engine_version_bump_type | Yes | Yes | Specifies the Semvar segment (`major`, `minor`, `patch`) to bump before releasing package
engine_disable_cleanup | Yes | Yes | Specifies if the engine should cleanup the working directory on exit

	TODO: specify the missing `BRANCH` release style settings.

As mentioned above, all settings can be specified via Environmental variable. All you need to do is convert the setting to uppercase
and then prefix it with `CAPSULE_`. So `pypi_password` can be set with `CAPSULE_PYPI_PASSWORD` and `engine_cmd_test` with `CAPSULE_ENGINE_CMD_TEST`

### Example System Configuration File

Here's what an example system configuration file might look like:

```
source_git_parent_path: /srv/myclonefolder
source_github_api_endpoint: https://git.mycorpsubnet.example.com/v2
source_github_web_endpoint: https://git.mycorpsubnet.example.com/v2
```

## Step pre/post hooks and overrides

CapsuleCD is completely customizable, to the extent that you can run your own Ruby code as `pre` and `post` hooks before every step. 
If that's not enough, you can also completely override the step itself, allowing you to use your own business logic.
To add a `pre`/`post` hook or override a step, just modify your config `yml` file by adding the step you want to modify, and 
specify `pre`, `post` or `override` as a subkey. Then specify your multiline ruby script:

	---
      source_configure:
        pre: |
          # this is my multiline ruby script
          # the pre hook script runs before the actual step (source_configure) executes
          # we have access to any of the specified instance variables here.
          # check the documentation for more information.
          puts "override pre_source_configure" 
          `git clone ...`
        override: |
          # override scripts can be used to completely replace the built-in step script.
          # to ensure that you are compatible with the capsulecd runner, please ensure that you
          # populate all the correct instance variables.
          # see the documentation for more information
          puts "override source_configure"
        post: |
          # post scripts run after the step (source_configure) executes
          # you can override any instance variables here, do additional cleanup or anything else you want.
          puts "override post_source_configure"
      build_step:
        post: |
          # post build step runs after the build_step runs
          # within the script you have access to all instance variables and other methods defined in the engine.
          puts "override post_build_step" + @source_git_local_path

# Testing

## Test suite and continuous integration

CapsuleCD provides an extensive test-suite based on rspec and a full integration suite which uses VCR. 
You can run the unit tests with `rake  test`. The integration tests can be run by `rake 'spec:<package_type>'`. 
So to run the Python integration tests you would call `rake 'spec:python'`.

CircleCI is used for continuous integration testing: <https://circleci.com/gh/AnalogJ/capsulecd>

# Contributing

If you'd like to help improve CapsuleCD, clone the project with Git by running:

    $ git clone git://github.com/AnalogJ/capsulecd
    
Work your magic and then submit a pull request. We love pull requests!

If you find the documentation lacking, help us out and update this README.md. If you don't have the time to work on CapsuleCD, but found something we should know about, please submit an issue.

## To-do List

We're actively looking for pull requests in the following areas:

- CapsuleCD Engines for other languages
	- C#
	- Objective C
	- Dash
	- Go
	- Java
	- Lua
	- Rust
	- Scala
	- Swift
	- [Any others you can think of](https://libraries.io/)
- CapsuleCD Sources
	- GitLab
	- Bitbucket
	- Beanstalk
	- Kiln
	- Any others you can think of


# Versioning

We use SemVer for versioning. For the versions available, see the tags on this repository.

# Authors

Jason Kulatunga - Initial Development -  [@AnalogJ](https://github.com/AnalogJ)

# License

CapsuleCD is licensed under the MIT License - see the [LICENSE.md](https://github.com/AnalogJ/capsulecd/blob/master/LICENSE.md) file for details

