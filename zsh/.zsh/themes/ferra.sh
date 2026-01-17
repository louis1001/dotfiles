#!/bin/sh
# Base16 Ferra - Shell color setup script
# Author: Lio (https://github.com/lio)

# 1. Color Definitions (Hex)
color00="2b292e" # Base 00 - Black
color01="e06b74" # Base 08 - Red
color02="98c379" # Base 0B - Green
color03="e5c07b" # Base 0A - Yellow
color04="61afef" # Base 0D - Blue
color05="c678dd" # Base 0E - Magenta
color06="56b6c2" # Base 0C - Cyan
color07="e0e0e0" # Base 05 - White
color08="6f6874" # Base 03 - Bright Black
color09=$color01 # Bright Red
color10=$color02 # Bright Green
color11=$color03 # Bright Yellow
color12=$color04 # Bright Blue
color13=$color05 # Bright Magenta
color14=$color06 # Bright Cyan
color15="fcfcfc" # Base 07 - Bright White
color16="d08770" # Base 09
color17="be5046" # Base 0F
color18="363338" # Base 01
color19="423f46" # Base 02
color20="b1b0b5" # Base 04
color21="f0f0f0" # Base 06

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

# 4. Apply Background/Foreground (Optional - remove if you prefer terminal default)
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
