function nx-rebuild() {
	DOTFILES=$HOME/.dotfiles#"$1"
    darwin-rebuild switch --flake $DOTFILES
}

function nx-update() {
	cd $HOME/.dotfiles
	nix flake update
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

function setwpp() {
    # Define the wallpapers directory - adjust this path to match your dotfiles structure
    WALLPAPER_DIR="$HOME/wallpapers/"
    
    # Check if the wallpaper directory exists
    if [ ! -d "$WALLPAPER_DIR" ]; then
        echo "\033[31mError: Wallpaper directory not found at $WALLPAPER_DIR\033[0m"
        echo "Please create the directory and add some wallpapers"
        return 1
    fi
    
    # Get a random wallpaper from the directory
    # Supporting common image formats: jpg, jpeg, png, heic
    WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.heic" \) | sort -R | head -1)
    
    # Check if any wallpapers were found
    if [ -z "$WALLPAPER" ]; then
        echo "\033[31mError: No wallpapers found in $WALLPAPER_DIR\033[0m"
        echo "Please add some wallpapers (jpg, jpeg, png, or heic format)"
        return 1
    fi
    
    # Set the wallpaper
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$WALLPAPER\""
    
    # Show success message with the name of the wallpaper
    echo "\033[32mWallpaper changed to: $(basename "$WALLPAPER")\033[0m"
}

