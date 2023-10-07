#!/usr/bin/env bash

function api() {
	{ #helpers
		webtop() {
			declare container_id
			container_id="$(docker ps --filter "name=API" --format "{{.ID}}")"

			[[ -d "downloads" ]] || mkdir "downloads"

			[[ -n "${container_id}" ]] || {
				docker run -d \
					--name=API \
					-e PUID="$(id -u)" \
					-e PGID="$(id -g)" \
					-e TZ=America/Lima \
					-p 3000:3000 \
					-v ./downloads:/config/Downloads \
					--shm-size="1gb" \
					--restart unless-stopped \
					lscr.io/linuxserver/webtop:ubuntu-xfce

				sleep 2

				container_id="$(docker ps --filter "name=API" --format "{{.ID}}")"
				docker exec "${container_id}" bash -c "sed -i 's/value=\"Greybird\"/value=\"Greybird-dark\"/' \"/etc/xdg/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml\""
				docker exec "${container_id}" bash -c "sed -i 's/value=\"Greybird\"/value=\"Greybird-dark\"/' \"/config/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml\""
			}
		}

		filebrowser() {
			declare filebrowser_url="https://github.com/filebrowser/filebrowser/releases/download/v2.25.0/linux-amd64-filebrowser.tar.gz"
			declare path_filebrowser_dir="${PWD}/filebrowser"

			[[ -d "${path_filebrowser_dir}" ]] || mkdir -p "${path_filebrowser_dir}"

			pushd "${path_filebrowser_dir}" >/dev/null || exit 1

			[[ -f "${filebrowser_url##*/}" ]] || wget "${filebrowser_url}"
			[[ -f "${filebrowser_url##*/}" ]] && [[ ! -f "filebrowser" ]] && tar -xvf "${filebrowser_url##*/}" "filebrowser"

			[[ ! -f "config.json" ]] && [[ -f "filebrowser" ]] &&
				./filebrowser config init >/dev/null &&
				./filebrowser config set --auth.method=noauth >/dev/null &&
				./filebrowser users add admin admin --perm.admin=true >/dev/null &&
				./filebrowser config export ./config.json >/dev/null &&
				sed -i 's/"theme": [^\"]*"/"theme": "dark/g' ./config.json &&
				./filebrowser config import ./config.json >/dev/null

			popd >/dev/null || exit 1

			:

			type -ft filebrowser >/dev/null || {
				[[ -f "init_filebrowser.sh" ]] || {
					cat <<-EOF >./init_filebrowser.sh
						#!/usr/bin/env bash

						cd -- "${path_filebrowser_dir}" || exit 1

						exec ./filebrowser \\
						  --database "filebrowser.db" \\
						  --config config.json \\
						  --root "\${1:-"${PWD}/downloads"}"
					EOF

					chmod +x "init_filebrowser.sh"

					sudo ln -sf "${PWD}/init_filebrowser.sh" "/usr/local/bin/filebrowser"
				}
			}
		}
	}

	:

	[[ "${PWD##*/}" == "api" ]] || cd -- "api" || exit 1

	webtop
	filebrowser
}

api

