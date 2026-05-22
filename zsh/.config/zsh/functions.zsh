# Shell helper loader.
#
# Keep this file small. Put reusable shell functions in functions.d/*.zsh and
# prompt/completion/tool configuration in conf.d/*.zsh. Files are sourced in
# lexical order, so use numeric prefixes when load order matters.

for zsh_config_file in "${ZDOTDIR:-$HOME/.config/zsh}"/conf.d/*.zsh(N); do
  source "$zsh_config_file"
done
unset zsh_config_file

for zsh_function_file in "${ZDOTDIR:-$HOME/.config/zsh}"/functions.d/*.zsh(N); do
  source "$zsh_function_file"
done
unset zsh_function_file
