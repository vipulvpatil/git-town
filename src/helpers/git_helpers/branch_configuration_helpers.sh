#!/usr/bin/env bash


# Helper methods for managing the configuration of which branches
# are cut from which ones


# Returns the names of all branches that have this branch as their immediate parent
function child_branches {
  local current_branch=$1
  git config --get-regexp "^git-town\.branches\.parent\." | grep "$current_branch$" | sed 's/git-town\.branches\.parent\.//' | sed "s/ $current_branch$//"
}


# Calculates the "parents" property for the given branch
# out of the existing "parent" properties
function compile_parent_branches {
  local current_branch=$1

  # delete the existing entry
  delete_parents_entry "$current_branch"

  # re-create it from scratch
  local all_parent_branches=''
  local parent
  while [ "$current_branch" != "$MAIN_BRANCH_NAME" ]; do
    parent=$(parent_branch "$current_branch")
    all_parent_branches="$parent,$all_parent_branches"
    current_branch=$parent
  done

  # truncate the trailing comma
  # shellcheck disable=SC2001
  all_parent_branches=$(echo "$all_parent_branches" | sed 's/,$//')

  # save the result into the configuration
  git config git-town.branches.parents."$(normalized_branch_name "$1")" "$all_parent_branches"
}


# Removes the "parent" entry from the configuration
function delete_parent_entry {
  local branch_name=$1
  git config --unset "git-town.branches.parent.$branch_name"
}


# Removes the "parents" entry from the configuration
function delete_parents_entry {
  local branch_name=$1
  git config --unset git-town.branches.parents."$branch_name"
}


# Makes sure that we know all the parent branches
# Asks the user if necessary
# Aborts the script if not all branches become known.
function ensure_knows_parent_branches {
  local current_branch=$1

  if [ "$(knows_all_parent_branches "$current_branch")" = false ]; then
    # Here we don't have the parent branches list --> make sure we know all parents, then recompile it from all parents
    local parent

    while [ "$current_branch" != "$MAIN_BRANCH_NAME" ]; do
      if [ "$(knows_parent_branch "$current_branch")" = true ]; then
        parent=$(parent_branch "$current_branch")
        echo "automatically determined parent as '$parent'"
      else
        # here we don't know the parent of the current branch -> ask the user
        echo
        echo -n "Please enter the parent branch for $(echo_n_cyan_bold "$current_branch") ($(echo_n_dim "$MAIN_BRANCH_NAME")): "
        read parent
        if [ -z "$parent" ]; then
          parent=$MAIN_BRANCH_NAME
        fi
        if [ "$(has_branch "$parent")" == "false" ]; then
          echo_error_header
          echo_error "branch '$parent' doesn't exist"
          exit_with_error newline
        fi
        store_parent_branch "$current_branch" "$parent"
      fi
      current_branch=$parent
    done
    compile_parent_branches "$1"
  fi
}


# Returns whether we know the parent branch for the given branch
function knows_parent_branch {
  local branch_name=$1
  if [ -z "$(git config --get git-town.branches.parent."$branch_name")" ]; then
    echo false
  else
    echo true
  fi
}


# Returns whether we know the parent branches for the given branch
function knows_all_parent_branches {
  local branch_name=$1
  if [ -z "$(git config --get git-town.branches.parents."$branch_name")" ]; then
    echo false
  else
    echo true
  fi
}


# Returns the given branch name normalized so that it is compatible
# with Git's command-line interface for configuration data
function normalized_branch_name {
  local branch_name=$1
  echo "$branch_name" | tr '_' '-'
}


# Returns the names of all parent branches, in hierarchical order
function parent_branch {
  local branch_name=$1
  git config --get git-town.branches.parent."$(normalized_branch_name "$branch_name")"
}


# Returns the names of all parent branches,
# as a string list, in hierarchical order,
function parent_branches {
  local branch_name=$1
  git config --get git-town.branches.parents."$(normalized_branch_name "$branch_name")" | tr ',' '\n'
}


# Stores the given branch as the parent branch for the given branch
function store_parent_branch {
  local branch=$1
  local parent_branch=$2
  git config "git-town.branches.parent.$(normalized_branch_name "$branch")" "$parent_branch"
}

