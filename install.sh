sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh  | sed 's/env\ zsh\ -l//')"
wait
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
wait
git clone --recursive https://github.com/Marskey/.vim.git ~/.vim
wait

cp .zshrc ~/.zshrc
cp .gitconfig ~/.

# install vim vundle plugins
vim -c 'PluginInstall' -c 'qa!'
