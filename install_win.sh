cp win.zshrc ~/.zshrc
cp .minttyrc ~/.
cp .gitconfig ~/.
wait
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
wait
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
wait
chere -i -t mintty -s zsh
