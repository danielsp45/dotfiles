function ds() {
    cd ~/.dotfiles
    darwin-rebuild switch --flake .#"$1"
}

function copy(){
    pbcopy < $1
}

function new(){
    cd ~
    clear
    neofetch
}
