# Dev container shell customization

export CLICOLOR=1
export LANG="${LANG:-${LOCALE:-C.UTF-8}}"
export LC_ALL="${LC_ALL:-${LANG}}"

if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b)"
fi

alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias ..='cd ..'

cdw() {
    cd /workspaces/project
}

cdwp() {
    cd /var/www/html
}

cdplugins() {
    cd /var/www/html/wp-content/plugins
}

cdthemes() {
    cd /var/www/html/wp-content/themes
}

cduploads() {
    cd /var/www/html/wp-content/uploads
}

# VS Code統合ターミナルのTTYをCodexフック用に記録する
if [[ $- == *i* ]] && tty -s; then
  tty > "${CODEX_HOME:-$HOME/.codex}/vscode-terminal"
fi
