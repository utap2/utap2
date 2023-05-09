#!/bin/sh

# Credits: http://stackoverflow.com/a/750191

git filter-branch -f --env-filter "
    GIT_AUTHOR_NAME='Jordana_Lindner'
    GIT_AUTHOR_EMAIL='jordana.lindnerovadia@weizmann.ac.il'
    GIT_COMMITTER_NAME='Jordana_Lindner'
    GIT_COMMITTER_EMAIL='jordana.lindnerovadia@weizmann.ac.il'
  " HEAD
