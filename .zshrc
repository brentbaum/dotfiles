# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh


homebrew=/usr/local/bin:/usr/local/sbin
export PATH=$homebrew:$PATH

export TERM=xterm-16color Emacs 

export PATH=/usr/local/lib/python3.4/site-packages:$PATH
export PATH=~/dev/tf-cli:$PATH
#alias python='python3'
#alias pip='pip'
alias ipy="python -c 'import IPython; IPython.terminal.ipapp.launch_new_instance()'"

export JAVA_HOME=$(/usr/libexec/java_home) 
export PATH=$JAVA_HOME/bin:$PATH
export PATH=${PATH}:/Applications/Android\ Studio.app/sdk/platform-tools:/Applications/Android\ Studio.app/sdk/tools

export PATH=/usr/texbin:$PATH
export PATH=/Users/brent/Library/Haskell/bin:$PATH

export ARCHFLAGS=-Wno-error=unused-command-line-argument-hard-error-in-future
export GIT_EDITOR=atom

export REPORTTIME=10
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


alias j="autojump"
alias e=/Applications/Emacs.app/Contents/MacOS/Emacs "$@"
alias es=/Applications/Emacs.app/Contents/MacOS/Emacs --daemon
# alias emacs="/usr/local/bin/emacsclient -ct"
# alias es="/usr/local/bin/emacs --daemon"
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
# make lein cljsbuild fast.
export LEIN_FAST_TRAMPOLINE=y
alias cljsbuild="lein trampoline cljsbuild $@"

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


eval "$(pyenv init -)"


alg=/Users/brent/Dropbox/school_spring_2014/algorithms
school=/Users/brent/Dropbox/school_spring_2014
edu=/Users/brent/dev/edu-
school=/Users/brent/Dropbox/school_fall_2014
graphics=/Users/brent/Dropbox/school_fall_2014/cs4810
school=/Users/brent/Dropbox/school_spring_2015
school=/Users/brent/Dropbox/school_fall_2015
school=/Users/brent/Dropbox/school_spring_2016
helme=/Users/brent/dev/edu-
eval "$(rbenv init -)"
