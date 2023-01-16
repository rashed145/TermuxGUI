set -e
trap 'printf "\e[?1049l\e[23;0;0t"' EXIT INT RETURN
printf "\e[?1049h\e[22;0;0t"

update() {
	um="Updating Package Index"
	printf '\n\n\001\e[1;94m\002%s\001\e[0m\002\n\n' "$um"
	apt update
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
		msg+=("GUI Selected => $dn\n")
		break
	done
	df="${dn}[@]"
	all_pks+=(${!df})
}

i_extras() {
	while true; do
		read -e -p 'Extra packages to install(space separated)=> ' -a epk
		[ -z "$epk" ] && { msg+=("No extra packages added\n") && return; }
		for i in "${epk[@]}"; do
			apt-cache show "$i" &>/dev/null||{ npks+=("$i"); continue; }
			epks+=("$i")
		done
		[ -n "$npks" ] && { echo "Packages not found: \"${npks[@]}\""; unset npks; continue; }
		break
	done
	epks=("$(echo ${epks[@]}|tr ' ' '\n'|sort -u|tr '\n' ' ')")
	msg+=("Extra packages added => \'$(echo ${epks[@]})\'\n")
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
		msg+=("Terminal Selected => $te\n")
		break
	done
	all_pks+=($te)
}

s_vnc() {
	mkdir -p ~/bin
	printf "#!/usr/bin/bash\nvncserver -kill :1\nvncserver :1\nexport DISPLAY=:1\n" > ~/bin/gui
	chmod +x ~/bin/gui
	case "$dn" in
		XFCE) echo "xfce4-session &" >> ~/bin/gui ;;
		MATE) echo "mate-session &" >> ~/bin/gui ;;
		LXQt) echo "lxqt-session &" >> ~/bin/gui ;;
		Fluxbox) echo -e "fluxbox-generate_menu\nfluxbox &" >> ~/bin/gui ;;
		Openbox) echo "openbox-session &" >> ~/bin/gui
						mkdir -p ~/.config/openbox
						echo -e "xsetroot -solid gray\npypanel &" >> ~/.config/openbox/autostart ;;
	esac
}

i_pks() {
	upm="Upgrading Packages"
	printf '\n\001\e[1;92m\002%*s\001\e[0m\002\n\n' $[(COLUMNS/2)+(${#upm}/2)+1] "$upm"
	yes|apt full-upgrade && apt update
	inm="Installing Necessary Packages"
	printf '\n\001\e[1;93m\002%*s\001\e[0m\002\n\n' $[(COLUMNS/2)+(${#inm}/2)+1] "$inm"
	apt install x11-repo && apt update
        apt install tigervnc ${all_pks[@]}
}

overview() {
	for i in "${msg[@]}"; do
		printf "$i\n"
	done
	read -e -n1 -p "Press Enter or Space to Continue and press any key to cancel..." cn
	[ -z "$cn" ]||exit 0
}

__main() {
	for i in update i_de i_terminal i_extras overview; do
		printf "\e[H\e[J"
		$i
	done
}
__main
printf "\e[?1049l\e[23;0;0t"
i_pks
s_vnc
echo "export PATH=$PATH:~/bin" >>~/.profile
printf "\n\nUse command \`gui\` to start vnc server\nVNC=> 127.0.0.1:5901\n"
