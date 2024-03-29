defmodule Formin.Svc.Http.CorsPlug do
  import Plug.Conn

  def init(options) do
    options
  end

  def call(conn, _options) do
    conn
    |> put_req_header("access-control-allow-origin", "*")
  end
end

