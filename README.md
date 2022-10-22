# CozySocket

> A socket handling library.

This library wraps:

- `gen_tcp`
- `gen_udp`
- `gen_sctp`
- `ssl`

And, contains:

- a implementation for [SOCKS](https://en.wikipedia.org/wiki/SOCKS).

## Installation

Adding `cozy_lark` to your list of dependencies in `mix.exs`:

```elixir
defp deps do
  [
    {:cozy_socket, "~> 0.4"},
  ]
end
```

## Usage

For more information, see the [documentation](https://hexdocs.pm/cozy_socket).

# License

Apache License 2.0
