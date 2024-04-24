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
# Change git setup to only show tracked Files
$dotfiles config --local status.showUntrackedFiles no
wait
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh  | sed 's/env\ zsh\ -l//')"
wait
git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
wait
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
wait
curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
wait
if [[ $OSTYPE == 'darwin'* ]]; then
  echo 'macOS'
  xcode-select –install
  wait
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  wait
  brew install nvim
  wait
  brew install tmux
  wait
  brew install delta
  wait
  brew install rlwrap
  wait
  brew install ripgrep
  wait
  brew install lazygit
  wait
  brew isntall fzf
  wait
  brew install python3
  wait
  python3 -m pip install neovim-remote
  wait
elif [[ $OSTYPE == 'linux'* ]]; then
  echo 'linux'
  echo 'install nvim by youself'
fi

ln -s $HOME/.config/nvim_nvchad_conf/ $HOME/.config/nvim/lua/custom

echo done!
