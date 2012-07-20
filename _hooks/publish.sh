#!/usr/bin/env bash

function publish() {
  # executables prefix
  _prefix="/usr/bin"
  # git executable
  _git="/usr/local/git/bin/git"
  GREP="/usr/bin/grep"
  CUT="/usr/bin/cut"

  # site generation executable
  _generate="/Users/jim/.rvm/gems/ruby-1.9.2-p290@jamesferguson.github.com/bin/jekyll"
  # options for the generator
  _opts=(--no-safe --no-server --no-auto)

  # branch from which to generate site
  _origbranch="master"
  # branch holding the generated site
  _destbranch="gh-pages"

  # directory holding the generated site -- should be outside this repo
  _site="$("/usr/bin/mktemp" -d /tmp/_site.XXXXXXXXX)"
  # the current branch
  _currbranch="$($GREP "^*" < <("$_git" branch) | $CUT -d' ' -f2)"

  if [[ $_currbranch == $_origbranch ]]; then # we should generate the site
      # go to root dir of the repo
      cd "$("$_git" rev-parse --show-toplevel)"
      # generate the site
      "$_generate" ${_opts[@]} . "$_site"
      # switch to branch the site will be stored
      "$_git" checkout "$_destbranch"
      # overwrite existing files
      builtin shopt -s dotglob
      /bin/cp -rf "$_site"/* .
      builtin shopt -u dotglob
      # add any new files
      "$_git" add .
      # commit all changes with a default message
      "$_git" commit -a -m "updated site @ $(date +"%F %T")"
      # cleanup
      /bin/rm -rfv "$_site"
      # return
      "$_git" checkout "$_origbranch"
  fi
}

publish | tee "/Users/jim/Coding/jamesferguson.github.com/_hooks/log/publish.log"
