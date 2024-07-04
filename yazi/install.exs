#!/usr/bin/env elixir

Code.require_file(Path.expand("../helper.exs"))

# install yazi
case :os.type() do
  {:unix, :darwin} ->
    Helper.brew_install("yazi ffmpegthumbnailer unar jq poppler fd ripgrep fzf zoxide font-symbols-only-nerd-font")

  os ->
    IO.puts("Unsupported OS: #{inspect(os)}")
end

# create symlink
__ENV__.file
|> Path.dirname()
|> Helper.create_symlink(Path.expand("~/.config"))
