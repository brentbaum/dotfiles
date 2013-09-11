if [ -f ~/.bashrc ]; then
	source ~/.bashrc
fi
[[ -s "$HOME/dotfiles/.rvm/scripts/rvm" ]] && source "$HOME/dotfiles/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*
GOPATH=/Users/brent/go
PATH="$PATH:$GOPATH/bin"

# added by Anaconda 1.6.1 installer
export PATH="//anaconda/bin:$PATH"

alias mvim='mvim -v'
