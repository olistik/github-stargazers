# Github stargazers

Fetches the stars count from a Github repository.

This is mainly an excuse to play around with some design patterns.

## Result Object

The Result objects is used to make functions return richer values: either an error or a success, each with a symbolic code that can be used with pattern matching, and an optional payload composed by a hash.

## Promise/Either Monad

An hybrid of a Promise and the Either monad creates the abstraction of a chain of data transformations, that is executed only when invoking the instance method resolve.

## Usage

```
ruby github_stargazers.rb rails/rails
```

## License

This code is licensed under the AGPLv3 license.

See the LICENSE file for more details.

Developed with <3 by @olistik
