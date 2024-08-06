{ config, pkgs, ... }:

{
    # Home Manager needs a bit of information about you and the paths it should
    # manage.
    home.username = "gsd";
    home.homeDirectory = "/home/gsd";

    home.file = {
    # ".zshrc".source = ./../../zsh/linux/zshrc;
    };

    programs = {
        zsh = {
            enable = true;
            shellAliases = {
                cat="bat";
                nv="nvim";
                lv="lvim";
                v="nvim $(fzf)";
                ":q"="exit";
                cl="clear";

                bs="bin/server";
                bb="bin/build";
                br="bin/run";
                bt="bin/test";
                bf="bin/format";
                bl="bin/lint";
                bsh="bin/console";
                bcl="bin/clean";
                bst="bin/setup";
                bsr="bin/start";
                bsp="bin/stop";
                    
                m="mix";
                im="iex -S mix";
                ms="mix phx.server";
                mc="mix do clean, compile";
                mf="mix format";
                ml="mix lint";
                mt="mix test";
                mpr="mix phx.routes";
                mer="mix ecto.reset";

                mk="make";
                mkh="make help";
                mkl="make lint";
                mkc="make clean";
                mkr="make run";
                mkt="make test";
                mkut="make unit-tests";
                mkts="make tests";

                ohMyZsh = {
                    enable = true;
                    theme = "robbyrussell";
                    plugins = [
                        "git"
                        "npm"
                        "history"
                        "node"
                        "rust"
                        "deno"
                    ];
                };
            };
        };
    };

    imports = [ ./../common.nix ];
}
