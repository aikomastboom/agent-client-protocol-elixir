defmodule ACP.MethodNames do
  @moduledoc "JSON-RPC method names for all ACP methods."

  # Agent methods (called by clients, handled by agents)
  def initialize, do: "initialize"
  def authenticate, do: "authenticate"
  def session_new, do: "session/new"
  def session_load, do: "session/load"
  def session_set_mode, do: "session/set_mode"
  def session_prompt, do: "session/prompt"
  def session_cancel, do: "session/cancel"
  def session_close, do: "session/close"

  # Unstable agent methods
  def session_fork, do: "session/fork"
  def session_resume, do: "session/resume"
  def session_list, do: "session/list"
  def session_set_config_option, do: "session/set_config_option"
  def session_set_model, do: "session/set_model"

  # Client methods (called by agents, handled by clients)
  def session_request_permission, do: "session/request_permission"
  def session_update, do: "session/update"
  def fs_write_text_file, do: "fs/write_text_file"
  def fs_read_text_file, do: "fs/read_text_file"
  def terminal_create, do: "terminal/create"
  def terminal_output, do: "terminal/output"
  def terminal_release, do: "terminal/release"
  def terminal_wait_for_exit, do: "terminal/wait_for_exit"
  def terminal_kill, do: "terminal/kill"

  @doc "All agent method names as a list."
  def agent_methods do
    [
      initialize(),
      authenticate(),
      session_new(),
      session_load(),
      session_set_mode(),
      session_prompt(),
      session_cancel(),
      session_close(),
      session_fork(),
      session_resume(),
      session_list(),
      session_set_config_option(),
      session_set_model()
    ]
  end

  @doc "All client method names as a list."
  def client_methods do
    [
      session_request_permission(),
      session_update(),
      fs_write_text_file(),
      fs_read_text_file(),
      terminal_create(),
      terminal_output(),
      terminal_release(),
      terminal_wait_for_exit(),
      terminal_kill()
    ]
  end
end
