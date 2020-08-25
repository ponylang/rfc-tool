# rfc-tool

A tool for modifying Pony RFCs

## Status

[![Actions Status](https://github.com/ponylang/rfc-tool/workflows/vs-ponyc-latest/badge.svg)](https://github.com/ponylang/rfc-tool/actions)

Production ready.

## Installation

The rfc-tool requires [corral](https://github.com/ponylang/corral) to be installed.

```bash
git clone https://github.com/ponylang/rfc-tool
cd rfc-tool
make
sudo make install
```

## Usage

### Verify an RFC

```console
$ rfc-tool verify tests/rfc-pre.md
tests/rfc-pre.md is a valid RFC
```

### Complete an RFC

```console
$ rfc-tool complete tests/rfc-pre.md \
  https://github.com/ponylang/rfcs/pull/0000 \
  https://github.com/ponylang/ponyc/issues/0000
```

```markdown
- Feature Name: foo-bar-foobar
- Start Date: 2016-05-22
- RFC PR: https://github.com/ponylang/rfcs/pull/0000
- Pony Issue: https://github.com/ponylang/ponyc/issues/0000

...
```

Use the `--edit` option to modify the file in place.
