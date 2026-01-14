#!/bin/bash

# 检测系统类型
if [ -f /etc/fedora-release ]; then
  PKG_MANAGER="dnf"
elif [[ $OSTYPE == 'darwin'* ]]; then
  PKG_MANAGER="brew"
else
  PKG_MANAGER="brew"
fi

git init --bare $HOME/.dotfiles
wait
dotfiles="/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME"
$dotfiles remote add origin https://github.com/Marskey/dotfiles.git
wait
$dotfiles fetch
wait
$dotfiles checkout -b main --track origin/main
wait
$dotfiles submodule init
wait
$dotfiles submodule update
wait
# Change git setup to only show tracked Files
$dotfiles config --local status.showUntrackedFiles no
wait

# Install oh-my-zsh about
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh  | sed 's/env\ zsh\ -l//')"
wait
git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
wait
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
wait
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
wait
# oh-my-zsh done

# 只在非 Fedora 系统上安装 Homebrew
if [[ $PKG_MANAGER != "dnf" ]]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  wait

  if [[ $OSTYPE == 'darwin'* ]]; then
    echo 'macOS'
    xcode-select –install
    wait
  elif [[ $OSTYPE == 'linux'* ]]; then
    echo 'linux'
    (echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> /root/.bashrc
  fi
fi

$PKG_MANAGER install nvim
wait

# tmux about
$PKG_MANAGER install tmux
wait
git clone https://github.com/Morantron/tmux-fingers $HOME/.config/tmux/plugins/tmux-fingers
wait
# tmux done

# brew install delta
$PKG_MANAGER install diffr
wait
$PKG_MANAGER install rlwrap
wait
$PKG_MANAGER install ripgrep
wait
$PKG_MANAGER install lazygit
wait
$PKG_MANAGER install fzf
wait
$PKG_MANAGER install jq fd
wait
$PKG_MANAGER install python3
wait
python3 -m pip install neovim-remote
wait

ln -s $HOME/.config/nvim_nvchad_conf/ $HOME/.config/nvim/lua/custom

echo done!
