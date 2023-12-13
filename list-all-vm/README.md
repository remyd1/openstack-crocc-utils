# Project Name

List as supersonic all virtual machine from an OpenStack cluster

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [License](#license)

## Installation

```
go mod tidy
go build
```

## Usage

You need to source your openrc file or have a clouds.yaml configured.

In clouds.yaml case
```
export OS_CLOUD=MyOpenstack
```

Run with or without arg `--detail`
```
./list-all-vm --detail
```

## License

This code is licensed under the [MIT License](https://opensource.org/licenses/MIT).
