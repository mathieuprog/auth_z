defmodule AuthZ.AuthorizationPlugMixin do
  @moduledoc ~S"""
  Allows to create a plug enforcing authorization for protected routes.

  A user-defined module must `use` this module, making the user module a plug, and
  implement the `handle_authorization/3` and `handle_authentication_error/2`
  behaviours. The `handle_authorization/3` and `handle_authentication_error/2`
  callbacks receive a `Plug.Conn` struct and an atom identifying the set of routes
  that require authorization, and must return a `Plug.Conn` struct;
  `handle_authorization/3` additionally receives the logged in user.

  Example:

    ```
    defmodule MyAppWeb.Plugs.EnsureAuthorized do
      use AuthZ.AuthorizationPlugMixin

      import Plug.Conn
      import Phoenix.Controller

      alias MyApp.Accounts.User

      def handle_authentication_error(conn, :admin_routes),
        do: conn |> put_status(401) |> text("unauthenticated") |> halt()

      def handle_authorization(conn, %User{type: "admin"}, :admin_routes),
        do: conn

      def handle_authorization(conn, _, _),
        do: conn |> put_status(403) |> text("unauthorized") |> halt()
    end
    ```

    `EnsureAuthorized` is now a plug which can be used in the router:

    ```
    pipeline :ensure_admin_routes_authorized do
      plug MyAppWeb.Plugs.EnsureAuthorized,
        resource: :admin_routes
    end

    scope "/admin", MyAppWeb, as: :admin do
      pipe_through [:browser, :ensure_admin_routes_authorized]
      # code
    end
    ```
  """

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
