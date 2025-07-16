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

# Rescues a given file from the Downloads folder
function rescue() {
  local src
  if [ $# -gt 0 ]; then
    src=~/Downloads/"$1"
  else
	file=$(eza --sort oldest ~/Downloads | fzf --prompt="Select a file to rescue: " | tr -d "'")
	src=~/Downloads/"$file"
    [ -z "$file" ] && { echo "No file selected"; return 1; }
  fi
  mv "$src" .
}

function to() {
  local host initial_dir current_dir choice
  
  if [ -z "$1" ]; then
    echo "Usage: to user@host [local_directory]" >&2
    return 1
  fi

  host="$1"
  # Use "$2" as initial_dir if provided, otherwise default to "."
  initial_dir="${2:-.}"
  current_dir="$initial_dir"

  # Ensure the initial directory exists locally
  if [ ! -d "$current_dir" ]; then
    echo "Error: Local directory '$current_dir' not found." >&2
    return 1
  fi

  # Loop for directory navigation
  while true; do
    choice=$(find "$current_dir" -maxdepth 1 ! -path "$current_dir" -printf "%P\n" \
             | fzf --prompt="Local [$current_dir] ▶ " \
             ) || return 1 # User pressed ESC or cancelled

    if [ -d "$current_dir/$choice" ]; then
      current_dir="$current_dir/$choice"
    else
      # It's a file, or we're at the final directory for selection
      break
    fi
  done

  # Perform the scp operation
  # If choice is a directory itself, we want to copy the directory.
  # If choice is a file, we copy the file.
  # If initial_dir was provided but no specific file/dir selected,
  # it implies the initial_dir itself.
  if [ "$choice" == "$initial_dir" ]; then
      # This case shouldn't be reached if fzf is used to select an item.
      # If choice is empty, it means user selected current dir or didn't select anything
      # after navigating to a final directory.
      if [ -z "$choice" ]; then
          echo "No file or directory selected to copy." >&2
          return 1
      fi
  fi

  # Determine what to copy: the full path of the selected item
  local item_to_copy="$current_dir/$choice"
  
  # Special handling if the fzf selection was implicitly the current directory itself (i.e. nothing picked after navigating)
  # Or if initial_dir was explicitly specified and no further selection was made, implying the dir itself.
  if [ -z "$choice" ] && [ "$current_dir" == "$initial_dir" ]; then
      item_to_copy="$initial_dir"
  elif [ -z "$choice" ]; then # If choice is empty after navigation, it means the current_dir is the target
      item_to_copy="$current_dir"
  fi


  echo "Copying '$item_to_copy' to '$host:.' "
  scp -r "$item_to_copy" "$host:." # Use -r for recursive copy
}

function from() {
  local host initial_dir current_dir choice
  
  if [ -z "$1" ]; then
    echo "Usage: from user@host [remote_directory]" >&2
    return 1
  fi

  host="$1"
  # Use "$2" as initial_dir if provided, otherwise default to "."
  initial_dir="${2:-.}"
  current_dir="$initial_dir"

  # Check if the initial remote directory exists
  if ! ssh "$host" "[ -d '$current_dir' ]"; then
    echo "Error: Remote directory '$host:$current_dir' not found." >&2
    return 1
  fi

  # Loop for directory navigation
  while true; do
    choice=$(ssh "$host" \
      "find '$current_dir' -maxdepth 1 ! -path '$current_dir' -printf '%P\n'" \
      | fzf --prompt="Remote [$host:$current_dir] ▶ " \
    ) || return 1 # User pressed ESC or cancelled

    if ssh "$host" "[ -d '$current_dir/$choice' ]"; then
      current_dir="$current_dir/$choice"
    else
      # It's a file, or we're at the final directory for selection
      break
    fi
  done

  # Determine what to copy: the full path of the selected item on remote
  local remote_item_to_copy="$current_dir/$choice"

  # Special handling if the fzf selection was implicitly the current directory itself (i.e. nothing picked after navigating)
  # Or if initial_dir was explicitly specified and no further selection was made, implying the dir itself.
  if [ -z "$choice" ] && [ "$current_dir" == "$initial_dir" ]; then
      remote_item_to_copy="$initial_dir"
  elif [ -z "$choice" ]; then # If choice is empty after navigation, it means the current_dir is the target
      remote_item_to_copy="$current_dir"
  fi

  echo "Copying '$host:$remote_item_to_copy' to '.'"
  scp -r "$host:$remote_item_to_copy" . # Use -r for recursive copy
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

function remote-ched() {
	user="mca55928"
	folder="projects/F202500001HPCVLABEPICURE/${user}/CHED"
	code --folder-uri "vscode-remote://ssh-remote+$(user)@deucalion/${folder}"
}

function remote-adgd() {
	user="mca55928"
	folder="projects/F202500001HPCVLABEPICURE/${user}/ADGD"
	code --folder-uri "vscode-remote://ssh-remote+$(user)@deucalion/${folder}"
}

