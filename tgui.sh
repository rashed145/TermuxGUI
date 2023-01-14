set -e

i_x11() {
	yes|pkg --check-mirror up x11-repo tigervnc
}

i_de() {
	DE=(XFCE MATE LXQt Fluxbox Openbox)
	XFCE=(xfce4)
	MATE=('mate-*' marco)
	LXQt=(lxqt)
	Fluxbox=(fluxbox)
	Openbox=(openbox pypanel xorg-xsetroot)
	echo "Available GUI environments: "
	for i in ${!DE[@]}; do
		printf " $[i+1] ${DE[i]}\n"
	done
	while true; do
		read -e -n1 -p 'Select or leave empty to exit => ' de
		[ -z "$de" ] && exit
		[[ "$de" == [1-${#DE[@]}] ]]||{ echo "Invalid option selected" && continue; }
		dn="${DE[$[de-1]]}"
		echo "Selected $dn"
		break
	done
	df="${dn}[@]"
	all_pks+=(${!df})
}

i_extras() {
	read -e -p 'Extra packages to install(space separated)=> ' -a epks
	[ -z "$epks" ] && { echo "No extra packages added" && return; }
	echo "Added packages for installation."
	all_pks+=(${epks[@]})
}

i_terminal() {
	TE=(aterm st xfce4-terminal mate-terminal qterminal tilda roxterm kitty)
	echo "Available Terminal Emulators:"
	for i in ${!TE[@]}; do
		printf " $[i+1] ${TE[i]}\n"
	done
	while true; do
		read -e -n1 -p 'Select or leave empty for default => ' tn
		tn=${tn:-3}
		[[ "$tn" == [1-${#TE[@]}] ]]||{ echo "Invalid option selected" && continue; }
		te="${TE[tn-1]}"
		echo "Selected $te"
		break
	done
	all_pks+=($te)
}

s_vnc() {
	mkdir -p ~/bin
	printf "#!/usr/bin/bash\nvncserver -kill :1\nvncserver :1\nexport DISPLAY=:1\n"|tee ~/bin/gui
	chmod +x ~/bin/gui
	case "$dn" in
		XFCE) echo "xfce4-session &"|tee -a ~/bin/gui ;;
		MATE) echo "mate-session &"|tee -a ~/bin/gui ;;
		LXQt) echo "lxqt-session &"|tee -a ~/bin/gui ;;
		Fluxbox) echo -e "fluxbox-generate_menu\nfluxbox &"|tee -a ~/bin/gui ;;
		Openbox) echo "openbox-session &"|tee -a ~/bin/gui
						mkdir -p ~/.config/openbox
						echo -e "xsetroot -solid gray\npypanel &"|tee -a ~/.config/openbox/autostart ;;
	esac
}

i_pks() {
	apt install ${all_pks[@]}
}
printf "\e[?1049h"

for i in i_x11 i_de i_terminal i_extras i_pks s_vnc; do
	clear
	$i
done
printf "\e[?1049l"
echo "VNC=> 127.0.0.1:5901"
