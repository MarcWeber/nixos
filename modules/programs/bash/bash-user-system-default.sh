# Whenever you start a maybe login bash this file is sourced
# by ~/.bash_setup which is sourced by ~/.bashrc and ~/.bash_profile

# So customize ~/.bash_setup and use this file as source of inspiration

# This file represents this system's default.

if shopt -q progcomp 2> /dev/null; then
  # this file is sourced by ~/.bashrc and ~/.profile because you want
  # completion to be availale for all login and non login interactive shells.
  # this is a interactive shell

# no indentation! - scripts may be using here documents
@interactiveShellInit@

else
  # take care care to not emit anything which will break scp, rsync usage
  :; # dummy line
fi
