defmodule Formin.Svc.Runner do
  @moduledoc """
  Svc Runner

  post:contact[log=path;fifo=path],post:checklist[log=path]

  - log    `path`            | log file
  - fifo   `path`            | named pipe (fifo)
  - amqp   `host:port/queue` | rabbit mq
  - tcp    `host:port`       | tcp server
  - socket `path`            | linux socket
  - logger `regex`           | log file
  - stdout `regex`           | stdout
  - shell  `path`            | run shell script

  errors:
  - no actions
  - no method
  - no path
  """

  use GenServer

  alias Formin.Util

  require Logger

  @procname :svc_runner

  # ----- startup

  def start_link(args) do
    Util.IO.puts(~s[Runner])
    GenServer.start_link(__MODULE__, args, name: @procname)
  end

  @doc false
  def init(args) do
    {:ok, args}
  end

  # ----- api

  def event(msg) do
    ensure_started()
    GenServer.cast(@procname, {:fr_event, msg})
  end

  def flush do
    ensure_started()
    GenServer.call(@procname, :fr_flush)
  end

  def output(:file, path, json) do
    ensure_started()
    GenServer.cast(@procname, {:fr_file, path, json})
  end

  def output(:logger, pattern, json) do
    ensure_started()
    GenServer.cast(@procname, {:fr_logger, pattern, json})
  end

  def output(:stdout, pattern, json) do
    ensure_started()
    GenServer.cast(@procname, {:fr_stdout, pattern, json})
  end

  def output(:fifo, _path, _json) do
    ensure_started()
  end

  def output(:amqp, _path, _json) do
    ensure_started()
  end

  def output(:tcp, _path, _json) do
    ensure_started()
  end

  def output(:socket, _path, _json) do
    ensure_started()
  end

  def output(:shell, _path, _json) do
    ensure_started()
  end

  def output(_, _path, _json) do
    ensure_started()
  end

  # ----- callbacks

  def handle_cast({:fr_event, msg}, _from, state) do
    process_event(msg, state)
    {:noreply, state}
  end

  def handle_call(:fr_flush, state) do
    {:reply, :ok, state}
  end

  def handle_call(:fr_flush, _caller, state) do
    {:reply, :ok, state}
  end

  def handle_cast({:fr_stdout, pattern, json}, state) do
    regex = Regex.compile!(pattern)
    if String.match?(json, regex) do
      IO.puts(json)
    end
    {:noreply, state}
  end

  def handle_cast({:fr_file, path, json}, state) do
    {:ok, file} = File.open(path, [:append])
    IO.write(file, json)
    File.close(file)
    {:noreply, state}
  end

  def handle_cast({:fr_logger, pattern, json}, state) do
    regex = ~r/#{pattern}/
    if String.match?(json, regex) do
      Logger.info(json)
    end
    {:noreply, state}
  end

  # ----- helpers

  def process_event(msg, state) do
    IO.inspect({msg, state}, label: "PROCESS_EVENT")
  end

  defp ensure_started do
    unless Process.whereis(@procname), do: start_link([])
  end

end
