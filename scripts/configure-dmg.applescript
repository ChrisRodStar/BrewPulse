on run arguments
    set diskName to item 1 of arguments

    tell application "Finder"
        tell disk (diskName as string)
            open

            tell container window
                set current view to icon view
                set toolbar visible to false
                set statusbar visible to false
                set pathbar visible to false
                set bounds to {160, 120, 840, 550}
            end tell

            set viewOptions to icon view options of container window
            tell viewOptions
                set arrangement to not arranged
                set icon size to 112
                set text size to 14
            end tell
            set background picture of viewOptions to file ".background:BrewPulseInstallerBackground.tiff"

            set position of every item to {780, 110}
            set position of item "BrewPulse.app" to {170, 254}
            set position of item "Applications" to {510, 254}
            set extension hidden of item "BrewPulse.app" to true

            update without registering applications
            close
            open
            delay 1

            tell container window
                set bounds to {160, 120, 830, 540}
            end tell

            delay 1

            tell container window
                set bounds to {160, 120, 840, 550}
            end tell

            delay 2
        end tell
    end tell

end run
