# Typed

[![Build Status](https://api.travis-ci.com/getbannerman/typed.svg?branch=master)](https://travis-ci.com/getbannerman/typed)
[![Coverage Status](https://coveralls.io/repos/github/getbannerman/typed/badge.svg)](https://coveralls.io/github/getbannerman/typed)
[![Gem](https://img.shields.io/gem/v/bm-typed.svg)](https://rubygems.org/gems/bm-typed)
[![Downloads](https://img.shields.io/gem/dt/bm-typed.svg)](https://rubygems.org/gems/bm-typed)

## Description

`Typed` is a `dry-types` + `dry-struct` alternative. It provides a similar API in order to ease migration.
Compared to `dry-struct`, `Typed` has an improved support of "nullable" and "missable" fields:
- `Typed::String.nullable` : accepts a `String`, or `Nil`.
- `Typed::String.missable` : accepts a `String`, or no value at all (represented by `Typed::Undefined`).
- `Typed::String.nullable.missable` : accepts a `String`, `Nil`, or no value at all (represented by `Typed::Undefined`). This behavior is difficult to obtain with `dry-struct`.

`Typed` only targets the use-case of converting controller parameters into Ruby objects with proper type checks and coercions.

## Install

```ruby
gem 'bm-typed', require: 'typed'
```

## Documentation

Not yet.

## Maturity

This gem is a PoC and it shouldn't be considered production-ready.

## License

Copyright (c) 2018 [Bannerman](https://www.bannerman.com/), [Frederic Terrazzoni](https://github.com/fterrazzoni)

Licensed under the [MIT license](https://opensource.org/licenses/MIT).
