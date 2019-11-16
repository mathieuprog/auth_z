defmodule AuthZ.AuthorizationPlugMixin do
  @callback handle_authorization(Plug.Conn.t(), term, atom) :: Plug.Conn.t()
  @callback handle_authentication_error(Plug.Conn.t(), atom) :: Plug.Conn.t()

  defmacro __using__(_args) do
    this_module = __MODULE__

    quote do
      @behaviour unquote(this_module)

      def init(opts) do
        Keyword.fetch!(opts, :resource)

        opts
      end

      def call(conn, opts) do
        current_user = Map.get(conn.assigns, :current_user)

        authorize(conn, current_user, opts)
      end

      defp authorize(conn, nil, opts) do
        __MODULE__.handle_authentication_error(conn, Keyword.fetch!(opts, :resource))
      end

      defp authorize(conn, current_user, opts) do
        __MODULE__.handle_authorization(conn, current_user, Keyword.fetch!(opts, :resource))
      end
    end
  end
end
