#!/usr/bin/env bash

files=$(git log main..HEAD --oneline --name-only --pretty=format: | sort -u | sed '/^$/d')

if [ -z "$files" ]; then
    echo "No files changed.\n"
    exit 0
fi

ruby_files=$(echo "$files" | grep '\.rb$')
embedded_ruby_files=$(echo "$files" | grep '\.erb$')

js_files=$(echo "$files" | grep '\.js$')
css_files=$(echo "$files" | grep '\.css$')
html_files=$(echo "$files" | grep '\.html$')

prettier $js_files $css_files $html_files --write
rubocop -x $ruby_files $embedded_ruby_files

echo "Pre-push auto-formatting complete\n"
