# Whenever you start a maybe login zsh this file is sourced
# by ~/.zshrc

# So customize ~/.zshrc and use this file as source of inspiration

# This file represents this system's default.

case "$-" in
*i*) 
# no indentation! - scripts may be using here documents
@interactiveShellInit@
  ;;
*) 
;;
esac
