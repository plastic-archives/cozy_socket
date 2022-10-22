defprotocol CozySocket.Datagram.Protocol do
  @doc """
  Send a packet to the given recipient.
  """
  @spec send(t, iodata, term) :: :ok | {:error, term}
  def send(self, data, to)

  @doc """
  Receive a packet from the socket.
  """
  @spec recv(t) :: {:ok, {iodata, {CozySocket.Address.t(), :inet.port_number()}}} | {:error, term}
  def recv(self)

  @doc """
  Receive a packet with the given options or with the given size.
  """
  @spec recv(t, non_neg_integer | Keyword.t()) ::
          {:ok, {iodata, {CozySocket.Address.t(), :inet.port_number()}}} | {:error, term}
  def recv(self, length_or_options)

  @doc """
  Receive a packet with the given size and options.
  """
  @spec recv(t, non_neg_integer, Keyword.t()) ::
          {:ok, {iodata, {CozySocket.Address.t(), :inet.port_number()}}} | {:error, term}
  def recv(self, length, options)
end

defmodule CozySocket.Datagram do
  @type t :: CozySocket.Datagram.Protocol.t()

  use CozySocket.Helpers

  defdelegate send(self, packet, to), to: CozySocket.Datagram.Protocol
  defbang(send(self, packet, to), to: CozySocket.Datagram.Protocol)

  defdelegate recv(self), to: CozySocket.Datagram.Protocol
  defbang(recv(self), to: CozySocket.Datagram.Protocol)
  defdelegate recv(self, length_or_options), to: CozySocket.Datagram.Protocol
  defbang(recv(self, length_or_options), to: CozySocket.Datagram.Protocol)
  defdelegate recv(self, length, options), to: CozySocket.Datagram.Protocol
  defbang(recv(self, length, options), to: CozySocket.Datagram.Protocol)
end

defimpl CozySocket.Datagram.Protocol, for: Port do
  def send(self, data, {address, port}) do
    address =
      if address |> is_binary do
        address |> String.to_charlist()
      else
        address
      end

    :gen_udp.send(self, address, port, data)
  end

  def recv(self) do
    recv(self, 0, [])
  end

  def recv(self, length) when length |> is_integer do
    recv(self, length, [])
  end

  def recv(self, options) when options |> is_list do
    recv(self, 0, options)
  end

  def recv(self, length, options) do
    timeout = options[:timeout] || :infinity

    case :gen_udp.recv(self, length, timeout) do
      {:ok, {address, port, data}} ->
        {:ok, {data, {address, port}}}

      {:error, :closed} ->
        {:ok, nil}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
