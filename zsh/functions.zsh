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
    # ls the downloads folder organized by date
    ls -lt ~/Downloads
}

function rescue() {
    mv ~/Downloads/$1 ./
}
