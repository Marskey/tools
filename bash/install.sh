#!/bin/bash

# 检测系统类型
if [ -f /etc/fedora-release ]; then
  PKG_MANAGER="sudo dnf -y"
  # 预先获取 sudo 权限，并保持活跃
  sudo -v
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
elif [[ $OSTYPE == 'darwin'* ]]; then
  PKG_MANAGER="brew"
else
  PKG_MANAGER="brew"
fi

dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
if [ ! -d "$HOME/.dotfiles" ]; then
  git init --bare $HOME/.dotfiles
  $dotfiles remote add origin https://github.com/Marskey/dotfiles.git
  $dotfiles fetch
  $dotfiles checkout -b main --track origin/main
  $dotfiles submodule init
  $dotfiles submodule update
  $dotfiles config --local status.showUntrackedFiles no
else
  echo "dotfiles already exists, skipping..."
fi

# Install oh-my-zsh about
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | sed 's/env\ zsh\ -l//')"
else
  echo "oh-my-zsh already exists, skipping..."
fi

if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
fi

if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
fi

command -v zoxide &> /dev/null || curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
# oh-my-zsh done

# 只在非 Fedora 系统上安装 Homebrew
if [[ $PKG_MANAGER != "sudo dnf" ]]; then
  if ! command -v brew &> /dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    if [[ $OSTYPE == 'darwin'* ]]; then
      echo 'macOS'
      xcode-select –install
    elif [[ $OSTYPE == 'linux'* ]]; then
      echo 'linux'
      (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /root/.bashrc
    fi
  else
    echo "Homebrew already installed, skipping..."
  fi
fi

command -v nvim &> /dev/null || $PKG_MANAGER install nvim

# tmux about
command -v tmux &> /dev/null || $PKG_MANAGER install tmux

if [ ! -d "$HOME/.config/tmux/plugins/tmux-fingers" ]; then
  git clone https://github.com/Morantron/tmux-fingers $HOME/.config/tmux/plugins/tmux-fingers
fi
# tmux done

# brew install delta
command -v diffr &> /dev/null || $PKG_MANAGER install diffr
command -v rlwrap &> /dev/null || $PKG_MANAGER install rlwrap
command -v rg &> /dev/null || $PKG_MANAGER install ripgrep
command -v lazygit &> /dev/null || $PKG_MANAGER install lazygit
command -v fzf &> /dev/null || $PKG_MANAGER install fzf
command -v jq &> /dev/null || $PKG_MANAGER install jq
command -v fd &> /dev/null || $PKG_MANAGER install fd
command -v python3 &> /dev/null || $PKG_MANAGER install python3
python3 -c "import neovim" 2>/dev/null || python3 -m pip install neovim-remote

[ -L "$HOME/.config/nvim/lua/custom" ] || ln -s $HOME/.config/nvim_nvchad_conf/ $HOME/.config/nvim/lua/custom

echo done!
