# openproject

TL;DR:

* Installs, configures and runs OpenProject.


## Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with openproject](#setup)
    * [What openproject affects](#what-openproject-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with openproject](#beginning-with-openproject)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

Installs and configures openproject

## Setup

### What openproject affects

* apt sources
* packages form software repository
* database configurations

### Setup Requirements

* puppetlabs-apt
* puppetlabs-stdlib

### Beginning with openproject

## Usage

Call the class

```ruby
class { 'openproject' :
}
```

Or (preferrably) use include

```ruby
include openproject
```

## Reference

* [Openproject.org website documentation](https://www.openproject.org/docs)
* [installer.dat example](https://git.coop/webarch/openproject/-/issues/1)

## Limitations

* x86_64 architecture only
* Only Debian distribution is supported
* Only use this when using a dedicated VM
* no advanced configuration (yet)
* No tasks (yet)

## Development

* Make a fork
* do your thing, but ensure tests are added. No tests? No review
* Once done, squash all your commits into one
* Do pull request
* ???
* Get congratz or get feedback

