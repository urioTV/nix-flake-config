#!/usr/bin/env bash
set -euo pipefail

agent_dir="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"

# settings.json jest źródłem prawdy. Jego obecność chroni przed przypadkowym
# usunięciem zawartości błędnego katalogu wskazanego przez zmienną środowiskową.
if [[ ! -f "$agent_dir/settings.json" ]]; then
  printf 'pi-update: brak %s/settings.json — przerywam\n' "$agent_dir" >&2
  exit 1
fi

printf 'pi-update: usuwam wszystkie zainstalowane pakiety z %s\n' "$agent_dir"
rm -rf -- "$agent_dir/npm" "$agent_dir/git"

printf '%s\n' \
  'pi-update: pakiety zostały usunięte' \
  'Przy następnym uruchomieniu pi zostaną ponownie zainstalowane z settings.json.'
