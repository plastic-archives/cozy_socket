# CozySocket

> A socket handling library.

This library wraps `gen_tcp`, `gen_udp` and `gen_sctp`, `ssl` and implements
websockets and socks.

## Installation

Adding `cozy_lark` to your list of dependencies in `mix.exs`:

```elixir
defp deps do
  [
    {:cozy_socket, "~> 0.3"},
  ]
end
```

## Usage

For more information, see the [documentation](https://hexdocs.pm/cozy_socket).

### HTTP

```elixir
defmodule HTTP do
  def get(uri) when is_binary(uri) or is_list(uri) do
    get(URI.parse(uri))
  end

  def get(%URI{host: host, port: port, path: path}) do
    sock = CozySocket.TCP.connect! host, port, packet: :line
    sock |> CozySocket.Stream.send! "GET #{path || "/"} HTTP/1.1\r\nHost: #{host}\r\n\r\n"

    [_, code, text] = Regex.run ~r"HTTP/1.1 (.*?) (.*?)\s*$", sock |> CozySocket.Stream.recv!

    headers = headers([], sock) |> Enum.into(%{})

    sock |> CozySocket.packet! :raw
    body = sock |> CozySocket.Stream.recv!(String.to_integer(headers["Content-Length"]))

    { { String.to_integer(code), text }, headers, body }
  end

  defp headers(acc, sock) do
    case sock |> CozySocket.Stream.recv! do
      "\r\n" ->
        acc

      line ->
        [_, name, value] = Regex.run ~r/^(.*?):\s*(.*?)\s*$/, line

        headers([{ name, value } | acc], sock)
    end
  end
end
```

### WebCozySocket

#### Client

```elixir
socket = CozySocket.Web.connect! "echo.websocket.org"
socket |> CozySocket.Web.send! { :text, "test" }
socket |> CozySocket.Web.recv! # => {:text, "test"}
```

In order to connect to a TLS websocket, use the `secure: true` option:

```elixir
socket = CozySocket.Web.connect! "echo.websocket.org", secure: true
```

The `connect!` function also accepts other parameters, most notably the `path` parameter, which is used when the websocket server endpoint exists on a path below the domain ie. "example.com/websocket":

```elixir
socket = CozySocket.Web.connect! "example.com", path: "/websocket"
```

Note that websocket servers send ping messages. A pong reply from your client tells the server to keep the connection open and to send more data. If your client doesn't send a pong reply then the server will close the connection. Here's an example of how to get get both the data you want and reply to a server's pings:

```elixir
socket = CozySocket.Web.connect! "echo.websocket.org"
case socket |> CozySocket.Web.recv! do
  {:text, data} ->
    # process data
  {:ping, _ } ->
    socket |> CozySocket.Web.send!({:pong, ""})
end
```

#### Server

```elixir
server = CozySocket.Web.listen! 80
client = server |> CozySocket.Web.accept!

# here you can verify if you want to accept the request or not, call
# `CozySocket.Web.close!` if you don't want to accept it, or else call
# `CozySocket.Web.accept!`
client |> CozySocket.Web.accept!

# echo the first message
client |> CozySocket.Web.send!(client |> CozySocket.Web.recv!)
```

# License

Apache License 2.0
