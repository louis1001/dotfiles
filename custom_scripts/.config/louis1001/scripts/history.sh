#!/bin/sh

his () {
  args="$*"
  choices=$(history | grep $args | sed '1!G;h;$!d')

  filter_script="
import sys
import os

def parse_line(line):
  line = line.strip()

  index = line.index(' ')
  if index != -1:
    line = line[index:]

  if line[0] == '*':
    line = line[1:]

  return line.strip()

if len(sys.argv) == 1:
  os.exit(1)

choices = sys.argv[1].splitlines()
choices.reverse()

parsed_lines = map(parse_line, choices)
print('\n'.join(parsed_lines))
  "
  parsed_choices=$(python3 -c "$filter_script" $choices)

  choice=$(echo "$parsed_choices" |\
    gum choose --header "Command History")

  eval " $choice"
}
