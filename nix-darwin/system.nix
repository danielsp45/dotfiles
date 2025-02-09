{
    system = {
		# Used for backwards compatibility, please read the changelog before changing.
		# $ darwin-rebuild changelog
		stateVersion = 4;
        defaults = {
			menuExtraClock.Show24Hour = true;

			dock = {
				autohide = true;
				orientation = "bottom";
				show-recents = false;
				show-process-indicators = false;
				tilesize = 24;
				persistent-apps = [
					"/Applications/Spotify.app"
					"/Applications/Alacritty.app"
					"/Applications/Arc.app"
					"/Applications/Discord.app"
					"/System/Applications/Messages.app"
				];
				persistent-others = [];
			};

            NSGlobalDomain = {
                ApplePressAndHoldEnabled = false;
                # 120, 94, 68, 35, 25, 15
                InitialKeyRepeat = 15;
                # 120, 90, 60, 30, 12, 6, 2
                KeyRepeat = 2;
            };

			finder = {
				# bottom status bar
				ShowStatusBar = true;
				ShowPathbar = true;

				# default to list view
				FXPreferredViewStyle = "Nlsv";
				# full path in window title
				_FXShowPosixPathInTitle = true;
			};
        };

        keyboard = {
            enableKeyMapping = true;
            remapCapsLockToControl = true;
        };
    };

    security.pam.enableSudoTouchIdAuth = true;
}
