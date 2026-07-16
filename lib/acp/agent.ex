defmodule ACP.Agent do
  @moduledoc """
  Behaviour defining the interface that all ACP-compliant agents must implement.

  Agents handle requests from clients and execute tasks using language models and tools.

  Required callbacks: `initialize/1`, `authenticate/1`, `new_session/1`, `prompt/1`, `cancel/1`.
  Optional callbacks have default implementations that return `{:error, method_not_found}`.
  """

  @type result(t) :: {:ok, t} | {:error, ACP.Error.t()}

  @doc "Negotiate protocol capabilities."
  @callback initialize(ACP.InitializeRequest.t()) :: result(ACP.InitializeResponse.t())

  @doc "Authenticate the client."
  @callback authenticate(ACP.AuthenticateRequest.t()) :: result(ACP.AuthenticateResponse.t())

  @doc "Create a new conversation session."
  @callback new_session(ACP.NewSessionRequest.t()) :: result(ACP.NewSessionResponse.t())

  @doc "Process a user prompt within a session."
  @callback prompt(ACP.PromptRequest.t()) :: result(ACP.PromptResponse.t())

  @doc "Cancel ongoing operations for a session."
  @callback cancel(ACP.CancelNotification.t()) :: :ok | {:error, ACP.Error.t()}

  @doc "Close a session and free resources. Optional."
  @callback close_session(ACP.CloseSessionRequest.t()) :: result(ACP.CloseSessionResponse.t())

  @doc "Load an existing session. Optional - defaults to method_not_found error."
  @callback load_session(ACP.LoadSessionRequest.t()) :: result(ACP.LoadSessionResponse.t())

  @doc "Set the current mode for a session. Optional."
  @callback set_session_mode(ACP.SetSessionModeRequest.t()) ::
              result(ACP.SetSessionModeResponse.t())

  @doc "Handle extension method requests. Optional."
  @callback ext_method(ACP.ExtRequest.t()) :: result(ACP.ExtResponse.t())

  @doc "Handle extension notifications. Optional."
  @callback ext_notification(ACP.ExtNotification.t()) :: :ok | {:error, ACP.Error.t()}

  @optional_callbacks [
    load_session: 1,
    set_session_mode: 1,
    close_session: 1,
    ext_method: 1,
    ext_notification: 1
  ]

  defmacro __using__(_opts) do
    quote do
      @behaviour ACP.Agent

      @impl ACP.Agent
      def load_session(_args), do: {:error, ACP.Error.method_not_found()}

      @impl ACP.Agent
      def set_session_mode(_args), do: {:error, ACP.Error.method_not_found()}

      @impl ACP.Agent
      def close_session(_args), do: {:error, ACP.Error.method_not_found()}

      @impl ACP.Agent
      def ext_method(_args), do: {:ok, %ACP.ExtResponse{value: nil}}

      @impl ACP.Agent
      def ext_notification(_args), do: :ok

      defoverridable load_session: 1,
                     set_session_mode: 1,
                     close_session: 1,
                     ext_method: 1,
                     ext_notification: 1
    end
  end
end
