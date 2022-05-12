# Swoosh Gallery

Preview and display your Swoosh mailers to everyone. 

![](assets/docs/screenshot.png)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `swoosh_gallery` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:swoosh_gallery, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/swoosh_gallery>.

## Sample application

You can see Swoosh.Gallery in action with the Phoenix app included on `./sample`:

1. Run `mix do deps.get, phx.server`
2. Go to `http://localhost:4000/dev/emails`


### Static gallery

You can also generate static HTML files for you Gallery. This is useful when you want to expose the gallery without the need of a server.

```bash
mix swoosh.gallery.html --gallery Sample.Gallery --path="./_build/gallery"

open _build/gallery/index.html_
```


## Contributing

1. Download the project.
2. Run `mix do deps.get, tailwind.install`
3. Make some changes.
4. If you need add new tailwind styles, run `mix tailwind default`.
