defmodule ACP.V1.Client do
  @moduledoc """
  Behaviour defining the interface that ACP-compliant clients must implement.

  Clients are typically code editors that provide the interface between users and AI agents.

  Required callbacks: `request_permission/1`, `session_notification/1`.
  Optional callbacks have default implementations that return `{:error, method_not_found}`.
  """

  @type result(t) :: {:ok, t} | {:error, ACP.Error.t()}

  @doc "Request permission from the user for a tool call operation."
  @callback request_permission(ACP.V1.RequestPermissionRequest.t()) ::
              result(ACP.V1.RequestPermissionResponse.t())

  @doc "Handle session update notifications from the agent."
  @callback session_notification(ACP.V1.SessionNotification.t()) :: :ok | {:error, ACP.Error.t()}

  @doc "Write content to a text file. Optional."
  @callback write_text_file(ACP.V1.WriteTextFileRequest.t()) ::
              result(ACP.V1.WriteTextFileResponse.t())

  @doc "Read content from a text file. Optional."
  @callback read_text_file(ACP.V1.ReadTextFileRequest.t()) ::
              result(ACP.V1.ReadTextFileResponse.t())

  @doc "Create a new terminal and execute a command. Optional."
  @callback create_terminal(ACP.V1.CreateTerminalRequest.t()) ::
              result(ACP.V1.CreateTerminalResponse.t())

  @doc "Get terminal output and exit status. Optional."
  @callback terminal_output(ACP.V1.TerminalOutputRequest.t()) ::
              result(ACP.V1.TerminalOutputResponse.t())

  @doc "Release a terminal. Optional."
  @callback release_terminal(ACP.V1.ReleaseTerminalRequest.t()) ::
              result(ACP.V1.ReleaseTerminalResponse.t())

  @doc "Wait for terminal command to exit. Optional."
  @callback wait_for_terminal_exit(ACP.V1.WaitForTerminalExitRequest.t()) ::
              result(ACP.V1.WaitForTerminalExitResponse.t())

  @doc "Kill terminal command without releasing. Optional."
  @callback kill_terminal_command(ACP.V1.KillTerminalCommandRequest.t()) ::
              result(ACP.V1.KillTerminalCommandResponse.t())

  @doc "Handle extension method requests. Optional."
  @callback ext_method(ACP.ExtRequest.t()) :: result(ACP.ExtResponse.t())

  @doc "Handle extension notifications. Optional."
  @callback ext_notification(ACP.ExtNotification.t()) :: :ok | {:error, ACP.Error.t()}

  @optional_callbacks [
    write_text_file: 1,
    read_text_file: 1,
    create_terminal: 1,
    terminal_output: 1,
    release_terminal: 1,
    wait_for_terminal_exit: 1,
    kill_terminal_command: 1,
    ext_method: 1,
    ext_notification: 1
  ]

  defmacro __using__(_opts) do
    quote do
      @behaviour ACP.V1.Client

      @impl ACP.V1.Client
      def write_text_file(_args), do: {:error, ACP.Error.method_not_found()}

      @impl ACP.V1.Client
      def read_text_file(_args), do: {:error, ACP.Error.method_not_found()}

      @impl ACP.V1.Client
      def create_terminal(_args), do: {:error, ACP.Error.method_not_found()}

      @impl ACP.V1.Client
      def terminal_output(_args), do: {:error, ACP.Error.method_not_found()}

      @impl ACP.V1.Client
      def release_terminal(_args), do: {:error, ACP.Error.method_not_found()}

      @impl ACP.V1.Client
      def wait_for_terminal_exit(_args), do: {:error, ACP.Error.method_not_found()}

      @impl ACP.V1.Client
      def kill_terminal_command(_args), do: {:error, ACP.Error.method_not_found()}

      @impl ACP.V1.Client
      def ext_method(_args), do: {:ok, %ACP.ExtResponse{value: nil}}

      @impl ACP.V1.Client
      def ext_notification(_args), do: :ok

      defoverridable write_text_file: 1,
                     read_text_file: 1,
                     create_terminal: 1,
                     terminal_output: 1,
                     release_terminal: 1,
                     wait_for_terminal_exit: 1,
                     kill_terminal_command: 1,
                     ext_method: 1,
                     ext_notification: 1
    end
  end
end
