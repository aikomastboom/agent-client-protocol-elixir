defmodule ACP.Side do
  @moduledoc """
  Side behaviour for decoding JSON-RPC messages into typed structs.

  Each side (client or agent) knows how to decode incoming requests and notifications.
  """

  @callback decode_request(method :: String.t(), params :: map() | nil) ::
              {:ok, any()} | {:error, ACP.Error.t()}

  @callback decode_notification(method :: String.t(), params :: map() | nil) ::
              {:ok, any()} | {:error, ACP.Error.t()}
end

defmodule ACP.ClientSide do
  @moduledoc """
  Client side of an ACP connection.

  Decodes incoming requests (from agent) and notifications (from agent).
  """

  @behaviour ACP.Side

  @impl true
  def decode_request(_method, nil), do: {:error, ACP.Error.invalid_params()}

  def decode_request(method, params) do
    case method do
      "session/request_permission" ->
        ACP.RequestPermissionRequest.from_json(params) |> wrap(:request_permission)

      "fs/write_text_file" ->
        ACP.WriteTextFileRequest.from_json(params) |> wrap(:write_text_file)

      "fs/read_text_file" ->
        ACP.ReadTextFileRequest.from_json(params) |> wrap(:read_text_file)

      "terminal/create" ->
        ACP.CreateTerminalRequest.from_json(params) |> wrap(:create_terminal)

      "terminal/output" ->
        ACP.TerminalOutputRequest.from_json(params) |> wrap(:terminal_output)

      "terminal/kill" ->
        ACP.KillTerminalCommandRequest.from_json(params) |> wrap(:kill_terminal_command)

      "terminal/release" ->
        ACP.ReleaseTerminalRequest.from_json(params) |> wrap(:release_terminal)

      "terminal/wait_for_exit" ->
        ACP.WaitForTerminalExitRequest.from_json(params) |> wrap(:wait_for_terminal_exit)

      "_" <> custom_method ->
        {:ok, {:ext_method, %ACP.ExtRequest{method: custom_method, params: params}}}

      _ ->
        {:error, ACP.Error.method_not_found()}
    end
  end

  @impl true
  def decode_notification(_method, nil), do: {:error, ACP.Error.invalid_params()}

  def decode_notification(method, params) do
    case method do
      "session/update" ->
        {:ok, notif} = ACP.SessionNotification.from_json(params)
        {:ok, {:session_notification, notif}}

      "_" <> custom_method ->
        {:ok, {:ext_notification, %ACP.ExtNotification{method: custom_method, params: params}}}

      _ ->
        {:error, ACP.Error.method_not_found()}
    end
  end

  defp wrap({:ok, val}, tag), do: {:ok, {tag, val}}
end

defmodule ACP.AgentSide do
  @moduledoc """
  Agent side of an ACP connection.

  Decodes incoming requests (from client) and notifications (from client).
  """

  @behaviour ACP.Side

  @impl true
  def decode_request(_method, nil), do: {:error, invalid_params_with_reason("Missing request params")}

  def decode_request(method, params) do
    with :ok <- validate_required_fields(method, params) do
      case method do
        "initialize" ->
          ACP.InitializeRequest.from_json(params) |> wrap(:initialize)

        "authenticate" ->
          ACP.AuthenticateRequest.from_json(params) |> wrap(:authenticate)

        "session/new" ->
          ACP.NewSessionRequest.from_json(params) |> wrap(:new_session)

        "session/load" ->
          ACP.LoadSessionRequest.from_json(params) |> wrap(:load_session)

        "session/set_mode" ->
          ACP.SetSessionModeRequest.from_json(params) |> wrap(:set_session_mode)

        "session/prompt" ->
          ACP.PromptRequest.from_json(params) |> wrap(:prompt)

        "session/list" ->
          ACP.ListSessionsRequest.from_json(params) |> wrap(:list_sessions)

        "session/fork" ->
          ACP.ForkSessionRequest.from_json(params) |> wrap(:fork_session)

        "session/resume" ->
          ACP.ResumeSessionRequest.from_json(params) |> wrap(:resume_session)

        "session/set_config_option" ->
          ACP.SetSessionConfigOptionRequest.from_json(params) |> wrap(:set_session_config_option)

        "session/set_model" ->
          ACP.SetSessionModelRequest.from_json(params) |> wrap(:set_session_model)

        "_" <> custom_method ->
          {:ok, {:ext_method, %ACP.ExtRequest{method: custom_method, params: params}}}

        _ ->
          {:error, ACP.Error.method_not_found()}
      end
    end
  end

  @impl true
  def decode_notification(_method, nil), do: {:error, invalid_params_with_reason("Missing request params")}

  def decode_notification(method, params) do
    with :ok <- validate_required_fields(method, params) do
      case method do
        "session/cancel" ->
          ACP.CancelNotification.from_json(params) |> wrap(:cancel)

        "_" <> custom_method ->
          {:ok, {:ext_notification, %ACP.ExtNotification{method: custom_method, params: params}}}

        _ ->
          {:error, ACP.Error.method_not_found()}
      end
    end
  end

  defp wrap({:ok, val}, tag), do: {:ok, {tag, val}}

  defp validate_required_fields(method, params) when is_map(params) do
    required_fields =
      case method do
        "initialize" -> ["protocolVersion"]
        "authenticate" -> ["methodId"]
        "session/new" -> ["cwd", "mcpServers"]
        "session/load" -> ["sessionId", "cwd", "mcpServers"]
        "session/set_mode" -> ["sessionId", "modeId"]
        "session/prompt" -> ["sessionId", "prompt"]
        "session/fork" -> ["sessionId", "cwd"]
        "session/resume" -> ["sessionId", "cwd"]
        "session/cancel" -> ["sessionId"]
        _ -> []
      end

    case Enum.find(required_fields, &(not Map.has_key?(params, &1))) do
      nil -> :ok
      field -> {:error, invalid_params_with_reason("Missing required field: #{field}")}
    end
  end

  defp invalid_params_with_reason(reason) do
    ACP.Error.with_data(ACP.Error.invalid_params(), %{"reason" => reason})
  end
end
