#!/usr/bin/env bash

set -euo pipefail

APP_IDS=(
  dotfiles
  oh_my_zsh
  zoxide
  neovim
  tmux
  riff
  rlwrap
  ripgrep
  lazygit
  fzf
  jq
  fd
)

APP_LABELS=(
  "Dotfiles"
  "Oh My Zsh"
  "zoxide"
  "Neovim"
  "tmux"
  "riff"
  "rlwrap"
  "ripgrep"
  "lazygit"
  "fzf"
  "jq"
  "fd"
)

APP_DESCRIPTIONS=(
  "Clone and check out Marskey/dotfiles"
  "Install Zsh, Oh My Zsh, and its completion plugins"
  "Install the smarter cd command"
  "Install Neovim and link its custom configuration"
  "Install tmux and tmux-fingers"
  "Install the riff diff viewer"
  "Install a readline wrapper"
  "Install the rg search tool"
  "Install the terminal Git UI"
  "Install the fuzzy finder"
  "Install the JSON processor"
  "Install the fd file finder"
)

component_is_installed() {
  local app=$1
  local zsh_custom=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

  case "$app" in
    dotfiles)
      [[ -d $HOME/.dotfiles ]]
      ;;
    oh_my_zsh)
      command -v zsh >/dev/null 2>&1 &&
        [[ -d $HOME/.oh-my-zsh ]] &&
        [[ -d $zsh_custom/plugins/zsh-autosuggestions ]] &&
        [[ -d $zsh_custom/plugins/zsh-syntax-highlighting ]]
      ;;
    zoxide)
      command -v zoxide >/dev/null 2>&1
      ;;
    neovim)
      command -v nvim >/dev/null 2>&1
      ;;
    tmux)
      command -v tmux >/dev/null 2>&1 &&
        [[ -d $HOME/.config/tmux/plugins/tmux-fingers ]]
      ;;
    riff | rlwrap | lazygit | fzf | jq | fd)
      command -v "$app" >/dev/null 2>&1
      ;;
    ripgrep)
      command -v rg >/dev/null 2>&1
      ;;
    *)
      return 1
      ;;
  esac
}

APP_SELECTED=()
APP_DISABLED=()
for ((i = 0; i < ${#APP_IDS[@]}; i++)); do
  if component_is_installed "${APP_IDS[i]}"; then
    APP_SELECTED+=(0)
    APP_DISABLED+=(1)
  else
    APP_SELECTED+=(1)
    APP_DISABLED+=(0)
  fi
done

MENU_ACTIVE=false
MENU_STTY=""
SUDO_KEEPALIVE_PID=""

cleanup() {
  if $MENU_ACTIVE; then
    if [[ -n $MENU_STTY ]]; then
      stty "$MENU_STTY" <&3 2>/dev/null || true
    fi
    printf '\033[?25h\033[?1049l' >&3
    exec 3>&-
    MENU_ACTIVE=false
  fi

  if [[ -n $SUDO_KEEPALIVE_PID ]]; then
    kill "$SUDO_KEEPALIVE_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT
trap 'exit 130' INT TERM HUP

draw_app_menu() {
  local cursor=$1
  local marker pointer color reset description

  printf '\033[H\033[2J' >&3
  printf '\033[1;36mSelect components to install\033[0m\n\n' >&3

  for ((i = 0; i < ${#APP_IDS[@]}; i++)); do
    marker='[ ]'
    pointer=' '
    color=''
    reset=''
    description="${APP_DESCRIPTIONS[i]}"

    if ((APP_DISABLED[i])); then
      marker='[-]'
      color='\033[2;37m'
      reset='\033[0m'
      description="$description (already installed)"
    elif ((APP_SELECTED[i])); then
      marker='[x]'
    fi
    if ((i == cursor)); then
      pointer='>'
      if ((!APP_DISABLED[i])); then
        color='\033[1;32m'
      fi
      reset='\033[0m'
    fi

    printf '%b%s %s %-26s%b %s\n' \
      "$color" "$pointer" "$marker" "${APP_LABELS[i]}" "$reset" \
      "$description" >&3
  done

  printf '\nInstalled components are disabled.\n' >&3
  printf 'Space: toggle  ↑/↓ or j/k: move  a: toggle all  Enter: install  q: quit\n' >&3
}

first_selectable_index() {
  for ((i = 0; i < ${#APP_IDS[@]}; i++)); do
    if ((!APP_DISABLED[i])); then
      printf '%s' "$i"
      return
    fi
  done

  printf '0'
}

next_selectable_index() {
  local cursor=$1
  local direction=$2
  local candidate

  for ((i = 0; i < ${#APP_IDS[@]}; i++)); do
    candidate=$(( (cursor + direction + ${#APP_IDS[@]}) % ${#APP_IDS[@]} ))
    if ((!APP_DISABLED[candidate])); then
      printf '%s' "$candidate"
      return
    fi
    cursor=$candidate
  done

  printf '%s' "$1"
}

select_apps() {
  local cursor
  local key sequence
  local selected_count selectable_count

  cursor=$(first_selectable_index)

  if [[ ${INSTALL_ALL:-0} == 1 ]]; then
    return
  fi

  if { exec 3<>/dev/tty; } 2>/dev/null; then
    :
  elif [[ -t 0 ]]; then
    exec 3>&0
  else
    printf 'No interactive terminal detected; installing all missing components.\n'
    return
  fi

  MENU_ACTIVE=true
  MENU_STTY=$(stty -g <&3)
  stty -echo -icanon min 1 time 0 <&3
  printf '\033[?1049h\033[?25l' >&3

  while true; do
    draw_app_menu "$cursor"
    key=''
    IFS= read -r -n 1 key <&3 || true

    case "$key" in
      $'\x1b')
        sequence=''
        IFS= read -r -n 2 sequence <&3 || true
        case "$sequence" in
          '[A') cursor=$(next_selectable_index "$cursor" -1) ;;
          '[B') cursor=$(next_selectable_index "$cursor" 1) ;;
        esac
        ;;
      k) cursor=$(next_selectable_index "$cursor" -1) ;;
      j) cursor=$(next_selectable_index "$cursor" 1) ;;
      ' ')
        if ((!APP_DISABLED[cursor])); then
          APP_SELECTED[cursor]=$((1 - APP_SELECTED[cursor]))
        fi
        ;;
      a)
        selected_count=0
        selectable_count=0
        for ((i = 0; i < ${#APP_SELECTED[@]}; i++)); do
          if ((!APP_DISABLED[i])); then
            selected_count=$((selected_count + APP_SELECTED[i]))
            selectable_count=$((selectable_count + 1))
          fi
        done
        for ((i = 0; i < ${#APP_SELECTED[@]}; i++)); do
          if ((!APP_DISABLED[i])); then
            if ((selectable_count > 0 && selected_count == selectable_count)); then
              APP_SELECTED[i]=0
            else
              APP_SELECTED[i]=1
            fi
          fi
        done
        ;;
      q)
        cleanup
        printf 'Installation cancelled.\n'
        exit 0
        ;;
      '') break ;;
    esac
  done

  cleanup
}

is_selected() {
  local wanted=$1

  for ((i = 0; i < ${#APP_IDS[@]}; i++)); do
    if [[ ${APP_IDS[i]} == "$wanted" ]]; then
      ((APP_SELECTED[i]))
      return
    fi
  done

  return 1
}

has_package_selection() {
  local app

  for app in oh_my_zsh neovim tmux riff rlwrap ripgrep lazygit fzf jq fd; do
    if is_selected "$app"; then
      return 0
    fi
  done

  return 1
}

show_selection() {
  local selected=()

  for ((i = 0; i < ${#APP_IDS[@]}; i++)); do
    if ((APP_SELECTED[i])); then
      selected+=("${APP_LABELS[i]}")
    fi
  done

  if ((${#selected[@]} == 0)); then
    printf 'Nothing selected; exiting.\n'
    exit 0
  fi

  printf 'Installing:\n'
  for ((i = 0; i < ${#selected[@]}; i++)); do
    printf '  - %s\n' "${selected[i]}"
  done
  printf '\n'
}

configure_package_manager() {
  if [[ -f /etc/fedora-release ]]; then
    PKG_MANAGER=(sudo dnf -y)
    PACKAGE_MANAGER_NAME=dnf
    sudo -v
    while true; do
      sudo -n true 2>/dev/null || exit
      sleep 50
    done &
    SUDO_KEEPALIVE_PID=$!
    return
  fi

  PACKAGE_MANAGER_NAME=brew
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ -x /opt/homebrew/bin/brew ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /home/linuxbrew/.linuxbrew/bin/brew ]]; then
      eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi
  else
    printf 'Homebrew already installed, skipping setup.\n'
  fi
  PKG_MANAGER=(brew)
}

install_package_if_missing() {
  local command_name=$1
  local brew_package=$2
  local dnf_package=${3:-$brew_package}
  local package=$brew_package

  if command -v "$command_name" >/dev/null 2>&1; then
    printf '%s already installed, skipping.\n' "$command_name"
    return
  fi

  if [[ $PACKAGE_MANAGER_NAME == dnf ]]; then
    package=$dnf_package
  fi
  "${PKG_MANAGER[@]}" install "$package"
}

install_riff() {
  if [[ $PACKAGE_MANAGER_NAME == dnf ]]; then
    if ! command -v cargo >/dev/null 2>&1; then
      if ! "${PKG_MANAGER[@]}" install cargo; then
        printf 'Warning: Failed to install Cargo; continuing without riff.\n' >&2
        return 0
      fi
    fi

    if ! cargo install riffdiff; then
      printf 'Warning: Failed to install riff through Cargo; continuing without riff.\n' >&2
    fi
    return 0
  fi

  if ! install_package_if_missing riff riff; then
    printf 'Warning: Failed to install riff; continuing without it.\n' >&2
  fi
  return 0
}

install_lazygit() {
  if [[ $PACKAGE_MANAGER_NAME == dnf ]]; then
    if ! "${PKG_MANAGER[@]}" copr enable dejan/lazygit; then
      printf 'Warning: Failed to enable the Lazygit COPR repository; continuing without lazygit.\n' >&2
      return 0
    fi
  fi

  if ! install_package_if_missing lazygit lazygit; then
    printf 'Warning: Failed to install lazygit; continuing without it.\n' >&2
  fi
  return 0
}

install_dotfiles() {
  dotfiles() {
    /usr/bin/git --git-dir="$HOME/.dotfiles/" --work-tree="$HOME" "$@"
  }

  if [[ -d $HOME/.dotfiles ]]; then
    printf 'Dotfiles already exist, skipping.\n'
    return
  fi

  git init --bare "$HOME/.dotfiles"
  dotfiles remote add origin https://github.com/Marskey/dotfiles.git
  dotfiles fetch
  dotfiles checkout -b main --track origin/main
  dotfiles submodule init
  dotfiles submodule update
  dotfiles config --local status.showUntrackedFiles no
}

install_oh_my_zsh() {
  local custom_dir=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

  if [[ ! -d $HOME/.oh-my-zsh ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | sed 's/env zsh -l//')"
  else
    printf 'Oh My Zsh already installed, skipping core installation.\n'
  fi

  if [[ ! -d $custom_dir/plugins/zsh-autosuggestions ]]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
      "$custom_dir/plugins/zsh-autosuggestions"
  fi
  if [[ ! -d $custom_dir/plugins/zsh-syntax-highlighting ]]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
      "$custom_dir/plugins/zsh-syntax-highlighting"
  fi
}

install_neovim_config() {
  local source=$HOME/.config/nvim_nvchad_conf
  local destination=$HOME/.config/nvim/lua/custom

  if [[ -L $destination || -e $destination ]]; then
    return
  fi
  if [[ ! -d $source ]]; then
    printf 'Warning: %s does not exist; skipping the Neovim config link.\n' "$source" >&2
    return
  fi

  mkdir -p "$(dirname "$destination")"
  ln -s "$source/" "$destination"
}

select_apps
show_selection

if has_package_selection; then
  configure_package_manager
fi

if is_selected dotfiles; then
  install_dotfiles
fi

if is_selected oh_my_zsh; then
  install_package_if_missing zsh zsh
  install_oh_my_zsh
fi

if is_selected zoxide; then
  command -v zoxide >/dev/null 2>&1 || \
    curl -fsSL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
fi

if is_selected neovim; then
  install_package_if_missing nvim neovim neovim
  install_neovim_config
fi

if is_selected tmux; then
  install_package_if_missing tmux tmux
  if [[ ! -d $HOME/.config/tmux/plugins/tmux-fingers ]]; then
    mkdir -p "$HOME/.config/tmux/plugins"
    git clone https://github.com/Morantron/tmux-fingers \
      "$HOME/.config/tmux/plugins/tmux-fingers"
  fi
fi

is_selected riff && install_riff
is_selected rlwrap && install_package_if_missing rlwrap rlwrap
is_selected ripgrep && install_package_if_missing rg ripgrep
is_selected lazygit && install_lazygit
is_selected fzf && install_package_if_missing fzf fzf
is_selected jq && install_package_if_missing jq jq
is_selected fd && install_package_if_missing fd fd-find

printf '\nDone!\n'
