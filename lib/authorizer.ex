defmodule AuthZ.Authorizer do
  @moduledoc ~S"""
  Declares the `authorize/3` callback to be implemented by context modules.

  The `authorize/3` function should receive an atom describing the action, the
  logged in user and the resource intended to be accessed; the function should
  return :ok in case the action is authorized, or a tuple containing :error as
  its first element and an atom describing the reason of unauthorized access as
  its second element (allowing to return different possible reasons of failure
  allows the controller for example to send more specific error messages to the
  logs or the view).

  Example:

    ```
    defmodule MyApp.Post.Policy do
      use AuthZ.Authorizer

      alias MyApp.Accounts.User
      alias MyApp.Blog.Post

      @unauthorized {:error, :unauthorized}

      def authorize(:edit_question, %User{id: user_id}, %Post{author: user_id}) do
        :ok
      end

      def authorize(:edit_question, _, _) do
        @unauthorized
      end
    end
    ```

  Using (`use`) this module injects the `authorized?/3` function simply calling
  `authorize/3` and returning a boolean instead of a tuple.
  """

  @callback authorize(atom, term, term) :: :ok | {:error, atom}

  defmacro __using__(_args) do
    this_module = __MODULE__

    quote do
      @behaviour unquote(this_module)

      def authorized?(action, current_user, resource) do
        :ok == authorize(action, current_user, resource)
      end
    end
  end
end
