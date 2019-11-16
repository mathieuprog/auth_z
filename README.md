# AuthZ

AuthZ is a simple authorization library that allows you to

* ensure users are permitted to access protected routes;
* encourage authorization rules in contexts.

## Implementing authorization rules in contexts

Authorization is easy to implement using the power of pattern matching. Below is an
example where only authors are authorized to edit their posts.

`use AuthZ.Authorizer` simply injects a behaviour, requiring your module to implement
`authorize/3`. This function should receive an atom describing the action, the logged
in user and the resource intended to be accessed; the function should return `:ok` in
case the action is authorized, or a tuple containing `:error` as its first element and
an atom describing the reason of unauthorized access as its second element (allowing to
return different possible reasons of failure allows the controller for example to send
more specific error messages to the logs or the view).

```elixir
defmodule MyApp.Post.Policy do
  use AuthZ.Authorizer

  alias DrivingLicense.Accounts.User
  alias DrivingLicense.Blog.Post

  @unauthorized {:error, :unauthorized}

  def authorize(:edit_question, %User{id: user_id}, %Post{author: user_id}) do
    :ok
  end

  def authorize(:edit_question, _, _) do
    @unauthorized
  end
end
```

`use AuthZ.Authorizer` also injects the function `authorized?/3` which simply calls
the user-defined function `authorize/3` and returns a boolean indicating
authorization success or failure.

## Protecting routes against unauthorized users

Authorization can be enforced for some routes. Create a module using (`use`) the
`AuthZ.AuthorizationPlugMixin` module; then implement the callbacks
`handle_authentication_error/2` and `handle_authorization/3`. Both callbacks
receive a `Plug.Conn` struct and an atom identifying the set of routes that require
authentication; `handle_authorization/3` additionally receives the logged in user.

```elixir
defmodule MyAppWeb.Plugs.EnsureAuthenticated do
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

You may then use the new plug into a pipeline and ensure that routes requiring
authorization are accessed by authorized users only.

```elixir
pipeline :ensure_admin_routes_authorized do
  plug MyAppWeb.Plugs.EnsureAuthorized,
    resource: :admin_routes
end

scope "/admin", MyAppWeb, as: :admin do
  pipe_through [:browser, :ensure_admin_routes_authorized]
  # code
end
```

## Installation

Add `auth_z` for Elixir as a dependency in your `mix.exs` file:

```elixir
def deps do
  [
    {:auth_z, "~> 0.1.0"}
  ]
end
```

## HexDocs

HexDocs documentation can be found at [https://hexdocs.pm/auth_z](https://hexdocs.pm/auth_z).
