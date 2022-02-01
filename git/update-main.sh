#!/bin/sh
# Get current branch
BRANCH=`git status | grep 'On branch' | sed 's/^.* //g'`

echo "| Current branch: '$BRANCH'"

# Determine if we need to use main or master
MAIN_BRANCH='master'
HAS_MAIN=`git branch --list main`
if [[ ! -z "$HAS_MAIN" ]];
  then MAIN_BRANCH='main';
fi

echo "| Updating main branch: '$MAIN_BRANCH'"
git checkout $MAIN_BRANCH && git fetch upstream && git rebase -i upstream/$MAIN_BRANCH && git push origin $MAIN_BRANCH

echo "| Successfully updated branch '$MAIN_BRANCH', and switching back to '$BRANCH'"
git checkout $BRANCH
