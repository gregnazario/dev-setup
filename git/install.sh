#!/bin/bash
BASH_CONFIG="$HOME/.bashrc"

# Determine whether to use bash_profile instead on Mac
if [ `uname -s` == 'Darwin' ]; then
  BASH_CONFIG="$HOME/.bash_profile"
fi

# Copy update script over
mkdir $HOME/bin
cp update-main.sh $HOME/bin/update-main.sh

# Install Aliases
echo "alias update-branch='git rebase -i main'
alias update-main='bash ~/bin/update-main.sh'" >> $BASH_CONFIG

