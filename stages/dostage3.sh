#!/bin/sh

#this script can be only called in chroot enviroment after stage0 installed.

# Warning: when switching from a 8bit to a 9bit font,
# the linux console will reinterpret the bold (1;) to
# the top 256 glyphs of the 9bit font. This does
# not affect framebuffer consoles
NORMAL="\\033[0;39m" # Standard console grey
SUCCESS="\\033[1;32m" # Success is green
WARNING="\\033[1;33m" # Warnings are yellow
FAILURE="\\033[1;31m" # Failures are red
INFO="\\033[1;36m" # Information is light cyan
BRACKET="\\033[1;34m" # Brackets are blue

#show info in cyan color, $1 is information.
showinfo()
{
	echo -e  $INFO"$1"$NORMAL
}

#show OK message in green color, $1 is information.
showOK()
{
	echo -e $SUCCESS"$1"$NORMAL
}

#show OK message in green color, $1 is information.
showFailed()
{
	echo -e $FAILURE"$1"$NORMAL
}

#check return code. show $1 if error.
err_check()
{
	if [ $? != 0 ]; then
		echo -e $FAILURE"$1"
		exit 1
	fi
}

showinfo "updating gtk2 modules"
gtk-query-immodules-2.0
err_check "gtk2 query module failed."

showinfo "updating gtk3 modules"
gtk-query-immodules-3.0
err_check "gtk3 query module failed."

showinfo "updating gtk icons.."
gtk-update-icon-cache
err_check "gtk update icon cache  failed."

showinfo "updating mime info..."
update-desktop-database /usr/share/applications
err_check "gtk update icon cache  failed."

showinfo "compile schemas.."
glib-compile-schemas /usr/share/glib-2.0/schemas
err_check "compile schema failed."

showinfo "updating hicolor icons"
xdg-icon-resource forceupdate --theme hicolor
err_check "update hicolor icon failed."

showinfo "updating gnome icons"
xdg-icon-resource forceupdate --theme gnome
err_check "update gnome icon failed."

showOK "all done. system ready to use"

