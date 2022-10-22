defmodule CozySocketTest do
  use ExUnit.Case

  test "a simple HTTP server" do
    defmodule HTTP do
      def get(uri) when is_binary(uri) or is_list(uri) do
        get(URI.parse(uri))
      end

      def get(%URI{host: host, port: port, path: path}) do
        sock = CozySocket.TCP.connect!(host, port, packet: :line)
        sock |> CozySocket.Stream.send!("GET #{path || "/"} HTTP/1.1\r\nHost: #{host}\r\n\r\n")

        [_, code, text] =
          Regex.run(~r"HTTP/1.1 (.*?) (.*?)\s*$", sock |> CozySocket.Stream.recv!())

        headers = headers([], sock) |> Enum.into(%{})

        sock |> CozySocket.packet!(:raw)
        body = sock |> CozySocket.Stream.recv!(String.to_integer(headers["Content-Length"]))

        {{String.to_integer(code), text}, headers, body}
      end

      defp headers(acc, sock) do
        case sock |> CozySocket.Stream.recv!() do
          "\r\n" ->
            acc

          line ->
            [_, name, value] = Regex.run(~r/^(.*?):\s*(.*?)\s*$/, line)

            headers([{name, value} | acc], sock)
        end
      end
    end

    assert {{200, "OK"}, _headers, _body} = HTTP.get("http://www.example.com")
  end
end
