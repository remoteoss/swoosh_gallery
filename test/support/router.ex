defmodule Support.Router do
  use Plug.Router

  plug(:match)
  plug(:dispatch)

  forward("/gallery", to: Support.Gallery)
end
