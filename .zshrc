# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh


homebrew=/usr/local/bin:/usr/local/sbin
export PATH=$homebrew:$PATH

export TERM=xterm-16color Emacs 

export PYTHONPATH="/usr/local/lib/python2.7/site-packages:$PYTHONPATH"
export PYTHONPATH="/usr/local/Cellar/opencv/2.4.9/lib/python2.7/site-packages/:$PYTHONPATH"

JAVA_HOME=/System/Library/Frameworks/JavaVM.framework/Versions/1.6.0
export PATH=$JAVA_HOME/bin:$PATH

export PATH=/usr/texbin:$PATH

[[ -d "${HOME}/bin" ]] && export PATH="${HOME}/bin:${PATH}"

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="robbyrussell"
#
#RVM
[[ -s "$HOME/.rvm/scripts/rvm" ]] && . "$HOME/.rvm/scripts/rvm"
#NVM
[ -s $HOME/.nvm/nvm.sh ] && . $HOME/.nvm/nvm.sh # This loads NVM


alias vim="mvim -v"
alias j="autojump"
alias e=/Applications/Emacs.app/Contents/MacOS/Emacs "$@"
alias es=/Applications/Emacs.app/Contents/MacOS/Emacs --daemon
# alias emacs="/usr/local/bin/emacsclient -ct"
# alias es="/usr/local/bin/emacs --daemon"
alias school="~/Dropbox/School\ Fall\ 2013"
alias dash="~/Dropbox/Collective/Dash"
datarep=~/Dropbox/School\ Fall\ 2013/Program\ \&\ Data\ Rep/
alias radar="~/Dropbox/Collective/radar"

function shortcut {
    local foo=$(pwd)
    echo "$1=$foo" >> ~/.zshrc
    zsh
    cd $($foo)
}

function makepdf {
    echo "Let me get on that..."
    latexmk -pdf $1
    rm $1.log $1.fdb_latexmk $1.fls $1.aux
    open $1.pdf
    echo "Finished!"
}

export GOPATH=~/Go

export CLASSPATH="$CLASSPATH:$HOME/bin/leiningen-2.0.0-preview10-standalone.jar"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable bi-weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment to change how often before auto-updates occur? (in days)
# export UPDATE_ZSH_DAYS=13

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want to disable command autocorrection
# DISABLE_CORRECTION="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Uncomment following line if you want to disable marking untracked files under
# VCS as dirty. This makes repository status check for large repositories much,
# much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(brew gem npm ruby rvm web-search zsh-syntax-highlighting)



source $ZSH/oh-my-zsh.sh

# bindkey -v

function chpwd() {
    emulate -L zsh
    ls -a
}
clojuredev=/Users/brent/Dropbox/Development/test_project
puzzle=/Users/brent/Dropbox/Development/test_project/src/test_project
cloj=/Users/brent/Dropbox/Development/clojure
os=/Users/brent/Dropbox/Development/os
matcher=/Users/brent/Dropbox/Development/clojure/matcher
alg=/Users/brent/Dropbox/school_spring_2014/algorithms
fish=/Users/brent/Dropbox/Development/fisheatfish
school=/Users/brent/Dropbox/school_spring_2014
edu=/Users/brent/Dropbox/Development/edu-
scrappy=/Users/brent/Dropbox/Development/clojure/scrappy
classify=/Users/brent/Dropbox/school_spring_2014/ai/classify-me-captain
