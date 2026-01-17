#!/bin/sh
# Base16 Dracula - Shell color setup script
# Author: Mike Barkmin (http://github.com/mikebarkmin) based on Dracula Theme (http://github.com/dracula)

# 1. Color Definitions (Hex)
color00="282a36" # Base 00 - Black
color01="ff5555" # Base 08 - Red
color02="50fa7b" # Base 0B - Green
color03="f1fa8c" # Base 0A - Yellow
color04="bd93f9" # Base 0D - Blue
color05="ff79c6" # Base 0E - Magenta
color06="8be9fd" # Base 0C - Cyan
color07="f8f8f2" # Base 05 - White
color08="6272a4" # Base 03 - Bright Black
color09=$color01 # Bright Red
color10=$color02 # Bright Green
color11=$color03 # Bright Yellow
color12=$color04 # Bright Blue
color13=$color05 # Bright Magenta
color14=$color06 # Bright Cyan
color15="ffffff" # Base 07 - Bright White
color16="ffb86c" # Base 09
color17="f1fa8c" # Base 0F
color18="3a3c4e" # Base 01
color19="44475a" # Base 02
color20="62d6e8" # Base 04
color21="f1f2f8" # Base 06

# 2. Helper to set colors
put_template() { printf '\033]4;%d;rgb:%s\033\\' $@; }
put_template_var() { printf '\033]%d;rgb:%s\033\\' $@; }
put_template_custom() { printf '\033]%s%s\033\\' $@; }

# 3. Apply Colors
put_template 0 $color00
put_template 1 $color01
put_template 2 $color02
put_template 3 $color03
put_template 4 $color04
put_template 5 $color05
put_template 6 $color06
put_template 7 $color07
put_template 8 $color08
put_template 9 $color09
put_template 10 $color10
put_template 11 $color11
put_template 12 $color12
put_template 13 $color13
put_template 14 $color14
put_template 15 $color15

# 4. Apply Background/Foreground
# 10=fg, 11=bg, 12=cursor
put_template_var 10 $color07
put_template_var 11 $color00
if [ "${TERM%%-*}" = "rxvt" ]; then
  put_template_var 708 $color00
fi

# 5. Clean up
unset -f put_template
unset -f put_template_var
unset -f put_template_custom
unset color00 color01 color02 color03 color04 color05 color06 color07
unset color08 color09 color10 color11 color12 color13 color14 color15
unset color16 color17 color18 color19 color20 color21
