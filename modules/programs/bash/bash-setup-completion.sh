# can be sourced by user to setup (unoptrusive) completion for bash

# 1) never source a completion script twice so that later profiles don't change
#    behaviour of earlier (more important ones)
# 2) allow users to opt-out from individual annoying completion scripts by
#    defining key
declare -A NIX_COMPL_SCRIPT_SOURCED

# potential problems (-rev 20179)
#  - It doesn't support filenames with spaces.
#  - It inserts a space after the filename when tab-completing in an
#    "svn" command.
#  - Many people find it annoying that tab-completion on commands like
#    "tar" only matches filenames with the "right" extension.
#  - Lluís reported bash apparently crashing on some tab completions.
# comment: Does this apply to complete.gnu-longopt or also to bash_completion?
NIX_COMPL_SCRIPT_SOURCED[complete.gnu-longopt]=1

nix_add_profile_completion(){

  # origin: bash_completion, slightly adopted
  # source script only once - allow user to use NIX_COMPL_SCRIPT_SOURCED to
  # opt out from bad scripts. If a user wants to reload all he can clear
  # NIX_COMPL_SCRIPT_SOURCED
  for s in "$1"/etc/bash_completion.d/*; do
    local base="${s/*\//}"
    [[ "${s##*/}" != @(*~|*.bak|*.swp|\#*\#|*.dpkg*|.rpm*) ]] &&
            [ \( -f "$s" -o -h "$s" \) -a -r "$s" ] &&
            [ -z "${NIX_COMPL_SCRIPT_SOURCED[$base]}" ] &&
            { . "$s"; NIX_COMPL_SCRIPT_SOURCED[$base]=1; }
  done
}

for p in $NIX_PROFILES; do
  nix_add_profile_completion "$p"
done
