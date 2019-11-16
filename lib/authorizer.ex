defmodule AuthZ.Authorizer do
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
