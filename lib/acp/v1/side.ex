defmodule ACP.V1.Side do
  @moduledoc """
  Side behaviour for decoding JSON-RPC messages into typed structs.

  Each side (client or agent) knows how to decode incoming requests and notifications.
  """

  @callback decode_request(method :: String.t(), params :: map() | nil) ::
              {:ok, any()} | {:error, ACP.Error.t()}

  @callback decode_notification(method :: String.t(), params :: map() | nil) ::
              {:ok, any()} | {:error, ACP.Error.t()}
end

defmodule ACP.V1.ClientSide do
  @moduledoc """
  Client side of an ACP connection.

  Decodes incoming requests (from agent) and notifications (from agent).
  """

  @behaviour ACP.V1.Side

  @impl true
  def decode_request(_method, nil), do: {:error, ACP.Error.invalid_params()}

  def decode_request(method, params) do
    case method do
      "session/request_permission" ->
        ACP.V1.RequestPermissionRequest.from_json(params) |> wrap(:request_permission)

      "elicitation/create" ->
        ACP.V1.ElicitationCreateRequest.from_json(params) |> wrap(:elicitation_create)

      "fs/write_text_file" ->
        ACP.V1.WriteTextFileRequest.from_json(params) |> wrap(:write_text_file)

      "fs/read_text_file" ->
        ACP.V1.ReadTextFileRequest.from_json(params) |> wrap(:read_text_file)

      "terminal/create" ->
        ACP.V1.CreateTerminalRequest.from_json(params) |> wrap(:create_terminal)

      "terminal/output" ->
        ACP.V1.TerminalOutputRequest.from_json(params) |> wrap(:terminal_output)

      "terminal/kill" ->
        ACP.V1.KillTerminalCommandRequest.from_json(params) |> wrap(:kill_terminal_command)

      "terminal/release" ->
        ACP.V1.ReleaseTerminalRequest.from_json(params) |> wrap(:release_terminal)

      "terminal/wait_for_exit" ->
        ACP.V1.WaitForTerminalExitRequest.from_json(params) |> wrap(:wait_for_terminal_exit)

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
        {:ok, notif} = ACP.V1.SessionNotification.from_json(params)
        {:ok, {:session_notification, notif}}

      "_" <> custom_method ->
        {:ok, {:ext_notification, %ACP.ExtNotification{method: custom_method, params: params}}}

      _ ->
        {:error, ACP.Error.method_not_found()}
    end
  end

  defp wrap({:ok, val}, tag), do: {:ok, {tag, val}}
end

defmodule ACP.V1.AgentSide do
  @moduledoc """
  Agent side of an ACP connection.

  Decodes incoming requests (from client) and notifications (from client).
  """

  @behaviour ACP.V1.Side

  @impl true
  def decode_request(_method, nil),
    do: {:error, invalid_params_with_reason("Missing request params")}

  def decode_request(method, params) do
    with :ok <- validate_required_fields(method, params) do
      case method do
        "initialize" ->
          ACP.V1.InitializeRequest.from_json(params) |> wrap(:initialize)

        "authenticate" ->
          ACP.V1.AuthenticateRequest.from_json(params) |> wrap(:authenticate)

        "session/new" ->
          ACP.V1.NewSessionRequest.from_json(params) |> wrap(:new_session)

        "session/load" ->
          ACP.V1.LoadSessionRequest.from_json(params) |> wrap(:load_session)

        "session/set_mode" ->
          ACP.V1.SetSessionModeRequest.from_json(params) |> wrap(:set_session_mode)

        "session/prompt" ->
          ACP.V1.PromptRequest.from_json(params) |> wrap(:prompt)

        "session/list" ->
          ACP.V1.ListSessionsRequest.from_json(params) |> wrap(:list_sessions)

        "session/fork" ->
          ACP.V1.ForkSessionRequest.from_json(params) |> wrap(:fork_session)

        "session/resume" ->
          ACP.V1.ResumeSessionRequest.from_json(params) |> wrap(:resume_session)

        "session/set_config_option" ->
          ACP.V1.SetSessionConfigOptionRequest.from_json(params)
          |> wrap(:set_session_config_option)

        "session/set_model" ->
          ACP.V1.SetSessionModelRequest.from_json(params) |> wrap(:set_session_model)

        "session/close" ->
          ACP.V1.CloseSessionRequest.from_json(params) |> wrap(:close)

        "_" <> custom_method ->
          {:ok, {:ext_method, %ACP.ExtRequest{method: custom_method, params: params}}}

        _ ->
          {:error, ACP.Error.method_not_found()}
      end
    end
  end

  @impl true
  def decode_notification(_method, nil),
    do: {:error, invalid_params_with_reason("Missing request params")}

  def decode_notification(method, params) do
    with :ok <- validate_required_fields(method, params) do
      case method do
        "session/cancel" ->
          ACP.V1.CancelNotification.from_json(params) |> wrap(:cancel)

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
        "session/close" -> ["sessionId"]
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
