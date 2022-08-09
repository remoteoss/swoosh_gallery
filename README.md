# Swoosh Gallery

Preview and display your [Swoosh](https://github.com/swoosh/swoosh) mailers to everyone. 

![](assets/docs/screenshot.png)

## Installation

The package can be installed by adding `swoosh_gallery` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:swoosh_gallery, "~> 0.1.0"}
  ]
end
```

The docs can be found at <https://hexdocs.pm/swoosh_gallery>.

## Sample application

You can see `Swoosh.Gallery` in action with the Phoenix app included in `./sample`:

1. Run `mix do deps.get, phx.server`
2. Go to `http://localhost:4000/dev/emails`


### Static gallery

You can also generate static HTML files for your `Gallery`. This is useful when you want to view the gallery without needing to run a server.

```bash
mix swoosh.gallery.html --gallery Sample.Gallery --path="./_build/gallery"

open _build/gallery/index.html_
```


## Contributing

1. Download the project.
2. Run `mix do deps.get, tailwind.install`
3. Make some changes.
4. If you need to add new tailwind styles, run `mix tailwind.default`.
