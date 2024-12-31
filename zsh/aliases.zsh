# terminal commands alias
alias cat="bat"
alias nv="nvim"
alias lv="lvim"
# alias fv="nvim $(fzf)"
alias :q="exit"
alias cl="clear"
alias ls="eza --icons"
alias l="ls -la --icons"
alias lg="lazygit"
alias fm="yazi"

# binary scripts
alias bs="bin/server"
alias bb="bin/build"
alias br="bin/run"
alias bt="bin/test"
alias bf="bin/format"
alias bl="bin/lint"
alias bsh="bin/console"
alias bcl="bin/clean"
alias bst="bin/setup"
alias bsr="bin/start"
alias bsp="bin/stop"

# elixir mix commands
alias m="mix"
alias im="iex -S mix"
alias ms="mix phx.server"
alias mc="mix do clean, compile"
alias mf="mix format"
alias ml="mix lint"
alias mt="mix test"
alias mpr="mix phx.routes"
alias mer="mix ecto.reset"

# make commands
alias mk="make"
alias mkh="make help"
alias mkl="make lint"
alias mkc="make clean"
alias mkr="make run"
alias mkt="make test"
alias mkut="make unit-tests"
alias mkts="make tests"
