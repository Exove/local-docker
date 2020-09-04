#!/usr/bin/env bash

# Source: https://github.com/manoj-apare/pre-commit, slightly modified.
#
# Redirect output to stderr.
exec 1>&2

# Color codes
red=`tput setaf 1`
green=`tput setaf 2`
blue=`tput setaf 4`
reset=`tput sgr0`

# Verify first there is something to check (staged files)
staged_files_count=`git diff-index --diff-filter=ACMRT --cached --name-only HEAD -- | wc -l`
if [ $staged_files_count -eq 0 ]; then
  exit 0
fi

# Notification
echo  "${blue}"
echo "# Running pre-commit git hook."
echo "==============================${reset}"


# Restricted branches. See README.md for details.
restricted_branches_list=("master development staging production")

# Debugging functions to be checked.
keywords=(dpm dpq dvm ddebug_backtrace print_r var_dump debug_backtrace console\.log kint)

# Join keywords array into a single string for grep and remove the separator from the start of the string.
keywords_for_grep=$(printf "|%s" "${keywords[@]}")
keywords_for_grep=${keywords_for_grep:1}

# Directories and files to be excluded during search.
exclude_dir_and_ext='\/features\/|\/contrib\/|\/devel\/|\/libraries\/|\/vendor\/|\.info$|\.png$|\.gif$|\.jpg$|\.ico$|\.patch$|\.htaccess$|\.sh$|\.ttf$|\.woff$|\.eot$|\.svg$'

# Define which coding standards PHPCS should use:
coding_standards_used='Drupal,DrupalPractice'

# Flag counter
errors_found=0
restricted_git_branch_warning=0
php_compile_syntax_error=0
debugging_function_found=0
merge_conflict_marker=0
coding_standard_violation=0

# Check for current branch, and warn if user is trying to commit to a
# branch in the restricted branches list.
BRANCH=`git rev-parse --abbrev-ref HEAD`
if [[ " ${restricted_branches_list[@]} " =~ " ${BRANCH} " ]]; then
  echo "${red}"
  echo "********************************************************************"
  echo "********************************************************************"
  echo "*****                                                          *****"
  echo -en "*****  You are on branch '$BRANCH'."
  for ((i=0; i< (35 - ${#BRANCH}); i++)){ echo -n " "; }
  echo "*****"
  echo "*****  Are you REALLY sure you want to commit to this branch?  *****"
  echo "*****                                                          *****"
  echo "*****  Pausing here for 7 secs to give you some time to think  *****"
  echo "*****  this thoroughly. Use it well.                           *****"
  echo "*****                                                          *****"
  echo "*****  You can hit [CMD + C] now to cancel.                    *****"
  echo "*****                                                          *****"
  echo "********************************************************************"
  echo "********************************************************************${reset}"
  echo
  restricted_git_branch_warning=1
  errors_found=$((errors_found + 1))
  sleep 7
fi


# Check for PHP syntax
# List php files added to commit
php_files_changed=`git diff-index --diff-filter=ACMRT --cached --name-only HEAD -- | egrep '\.php$|\.inc$|\.module|\.theme$'`
if [ -n "$php_files_changed" ]; then
  for FILE in $php_files_changed; do
    php -l $FILE > /dev/null 2>&1
    compiler_result=$?
    if [ $compiler_result -eq 255 ]; then
      php_compile_syntax_error=1
      errors_found=$((errors_found + 1))
      if [ $php_compile_syntax_error -eq 1 ]; then
        echo "${red}"
        echo "---------------------------"
        echo "---------------------------"
        echo "# FAIL: Compilation error(s):${reset}"
      fi
      php -l $FILE 2> /dev/null | grep 'Errors'
    fi
  done
  if [ $php_compile_syntax_error -eq 0 ]; then
    echo "${green}# PASS: PHP compiler check.${reset}"
  fi
else
  echo "${green}# SKIP: PHP compiler check  - no files for check.${reset}"
fi

# Check for debugging functions
# List all files added to commit excluding the exceptions
files_changed=`git diff-index --diff-filter=ACMRT --cached --name-only HEAD -- | egrep -v $exclude_dir_and_ext`
if [ -n "$files_changed" ]; then
  for FILE in $files_changed ; do
    for keyword in "${keywords[@]}" ; do
      # Find debugging function exists in file diff one by one.
      pattern="^\+(.*)?$keyword\s*\((.*)?"
      result_for_file=`git diff --cached $FILE | egrep -x "$pattern"`
      if [ -n "$result_for_file" ]; then
        debugging_function_found=1
        errors_found=$((errors_found + 1))
        if [ $debugging_function_found -eq 1 ]; then
          echo "${red}"
          echo "---------------------------"
          echo "---------------------------"
          echo "# FAIL: Debugging function(s):${reset}"
          echo
        fi
        echo "Debugging function" $keyword
        git grep -n $keyword $FILE | awk '{split($0,a,":");
          printf "\tfound in " a[1] " on line " a[2] "\n";
        }'
      fi
    done
  done
  if [ $debugging_function_found -eq 0 ]; then
    echo "${green}# PASS: Debugging functions check.${reset}"
  fi
else
  echo "${green}# SKIP: Debugging functions check  - no files for check.${reset}"
fi

# Check for Drupal coding standards
# List php files added to commit
php_files_changed=`git diff-index --diff-filter=ACMRT --cached --name-only HEAD -- | egrep -v $exclude_dir_and_ext | egrep '\.php$|\.module$|\.inc$|\.install$|\.test$|\.profile$|\.theme$|\.js$|\.css$|\.info$|\.txt$'`
if [ -n "$php_files_changed" ]; then
  phpcs_result=`phpcs --standard=$coding_standards_used --report=csv $php_files_changed`
  if [ "$phpcs_result" != "File,Line,Column,Type,Message,Source,Severity,Fixable" ]; then
    echo "${red}"
    echo "---------------------------"
    echo "---------------------------"
    echo "# FAIL: Coding standard check ($coding_standards_used):${reset}"
    echo
    phpcs --standard=$coding_standards_used $php_files_changed
    coding_standard_violation=1
    errors_found=$((errors_found + 1))
  fi
  if [ $coding_standard_violation -eq 0 ]; then
    echo "${green}# PASS: Coding standard check ($coding_standards_used).${reset}"
  fi
else
    echo "${green}# SKIP: Coding standard check ($coding_standards_used)  - no files for check.${reset}"
fi

# Check for merge conflict markers
# List all files added to commit
files_changed=`git diff-index --diff-filter=ACMRT --cached --name-only HEAD --`
if [ -n "$files_changed" ]; then
  for FILE in $files_changed; do
    # Find debugging function exists in file diff one by one.
    pattern="(<<<<|====|>>>>)+.*(\n)?"
    result_for_file=`egrep -in "$pattern" $FILE`
    if [ -n "$result_for_file" ]; then
      merge_conflict_marker=1
      errors_found=$((errors_found + 1))
      if [ $merge_conflict_marker -eq 1 ]; then
        echo "${red}"
        echo "---------------------------"
        echo "---------------------------"
        echo "# FAIL: Merge confict marker check:${reset}"
      fi
      echo $FILE
    fi
  done
  if [ $merge_conflict_marker -eq 0 ]; then
    echo "${green}# PASS: Merge conflict marker check.${reset}"
  fi
fi

# Decision maker
if [ $errors_found -gt 0 ]; then
  echo "${red}"
  echo "****************************************************"
  echo "****                                            ****"
  echo "****  Some issues found, please correect them.  ****"
  echo "****                                            ****"
  echo "****  ==> Git commit aborted!                   ****"
  echo "****                                            ****"
  echo "****  To force commit even with the errors,     ****"
  echo "****  you can bypass pre-commit hook execution  ****"
  echo "****  with -n / --no-veriry -flag:              ****"
  echo "****  $ git commit -n                           ****"
  echo "****                                            ****"
  if [ ! $restricted_git_branch_warning -eq 0 ]; then
    echo "****                                            ****"
    echo "****  NOTE!                                     ****"
    echo "****   You are about to commit to a restricted  ****"
    echo -n "****   branch '$BRANCH'."
    for ((i=0; i< (31 - ${#BRANCH}); i++)){ echo -n " "; }
    echo "****"
    echo "****                                            ****"
  fi
  echo "****************************************************"
  echo "${reset}"
  exit 1
fi
