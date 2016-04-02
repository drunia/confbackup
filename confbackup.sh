#!/bin/bash
#Simple backup configs (~/.config, ~/.kde, ...) in home directory
#Andrunin Dmitry, druniax@gmail.com

BACKUP_DIRS=".config .kde"
BACKUP_FILE="$HOME/.config_backup.tar"
BACKUP_FILE_GZ="$BACKUP_FILE.gz"

#Backup data
backup() {
  #Save old backup
  [ -e $BACKUP_FILE_GZ ] && mv $BACKUP_FILE_GZ $BACKUP_FILE.old
  local errors=0
  local lasterrors=0
  for dir in $BACKUP_DIRS; do
    echo -n "Backup "$HOME/$dir" to $BACKUP_FILE_GZ ... "
    [ -e "$HOME/$dir" ] || {
      echo "SKIP (Not exists)"
      continue
    }
    tar -rpf $BACKUP_FILE "$HOME/$dir" 1>/dev/null 2>errors
    errors=`expr $errors + $?`
    [ $errors -gt $lasterrors ] && {
      echo "WITH ERRORS"
      cat errors
    } || echo "OK"
    rm errors 2>/dev/null 1>&2
    lasterrors=$errors
  done 
  #Check backups operation on errors
  [ $errors -eq 0 ] && {
    #All ok
    rm $BACKUP_FILE.old 2>/dev/null
    #Compress backup 
    echo "Compressing ..."
    gzip -fq9 $BACKUP_FILE || errors=`expr $errors + 1`
  } || {
    #Restore old backup
    [ -e $BACKUP_FILE.old ] && mv $BACKUP_FILE.old $BACKUP_FILE_GZ
  } 
  return $errors
}

#Restore data
restore() {
  [ -e $BACKUP_FILE_GZ ] || {
    echo "Nothing to restore, try backup first."
    return 1;
  }
  echo -n "Restoring from $BACKUP_FILE_GZ ..."
  tar -xzpf $BACKUP_FILE_GZ 1>/dev/null 2>errors || {
    echo "WITH ERRORS"
    cat errors
    return 1
  }
  for dir in $BACKUP_DIRS; do
    cp -rf ."$HOME/$dir" "$HOME/" 1>/dev/null 2>errors || {
      echo "WITH ERRORS"
      cat errors
      return 1
    }
  done 
  echo "OK"
  rm -rf ."${HOME%/*}" 2>/dev/null 1>&1
  rm errors 2>/dev/null 1>&1
  return 0
}

#Show show
#$1 - error message
show_error() {
  echo -e "\e[0;31mError: $1"
  #Return default color terminal
  tput sgr0
  return 1
}

show_usage() {
  echo "Usage: $0 backup | restore"
  exit 1
}



#Check input parametrs
[ $# -lt 1 ] && {
  show_error "Not enought parameters!"
  show_usage
}

case $1 in 
  "backup") 
    #Try backup data
    backup && {
      echo "Backup data OK"
    } || echo "Backup data FAIL"
    ;;
  "restore") 
    #Try restore data 
    restore && {
      echo "Restore data OK"
    } || echo "Restore data FAIL"
    ;;
  * )
    show_error "Unknown parameter: $1"
    show_usage
    ;;
esac


exit 0
