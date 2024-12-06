function switch() {
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

function downloads() {
    eza -l --sort newest ~/Downloads
}

function rescue() {
    mv ~/Downloads/$1 ./
}
