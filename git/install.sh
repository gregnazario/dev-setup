#!/bin/bash
BASH_CONFIG="/home/$USER/.bashrc"

if [ `uname -s` == 'Darwin' ]; then
  BASH_CONFIG="/Users/$USER/.bash_profile"
fi
echo "alias update-branch='git rebase -i main'
alias update-main='bash ~/bin/update-main.sh'" >> $BASH_CONFIG
