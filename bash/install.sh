#!/bin/bash
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
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh  | sed 's/env\ zsh\ -l//')"
wait
git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
wait
if [[ $OSTYPE == 'darwin'* ]]; then
  echo 'macOS'
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  wait
  brew install --cask iterm2
  wait
  brew install nvim
  wait
  brew install tmux
  wait
elif [[ $OSTYPE == 'linux'* ]]; then
  echo 'linux'
  echo 'install nvim by youself'
fi

ln -s $HOME/.config/nvim_nvchad_conf/ $HOME/.config/nvim/lua/custom

echo done!
