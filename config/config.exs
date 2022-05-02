import Config

config :tailwind,
  version: "3.0.12",
  default: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../lib/swoosh/gallery/app.css
      --minify
    ),
    cd: Path.expand("../assets", __DIR__)
  ]
