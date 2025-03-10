#!/usr/bin/env bash
#  ┓ ┏┏┓┏┓┏┳┓┓┏┏┓┳┓┳┳┓┏┓┏┓
#  ┃┃┃┣ ┣┫ ┃ ┣┫┣ ┣┫┃┃┃┣ ┃┃
#  ┗┻┛┗┛┛┗ ┻ ┛┗┗┛┛┗┻┛┗┻ ┗┛
#

# HARDCODE Location & City
CITY=$(grep -oP '^\$CITY\s*=\s*\K.+' ~/.config/hypr/hyprlock.conf)
COUNTRY=$(grep -oP '^\$COUNTRY\s*=\s*\K.+' ~/.config/hypr/hyprlock.conf)

# Check if CITY and COUNTRY are valid
if [[ -n "$CITY" && -n "$COUNTRY" ]]; then
  # Fetch weather info for the detected city from wttr.in
  weather_info=$(curl -s "https://en.wttr.in/$CITY?format=%c+%C+%t" 2>/dev/null)

  # Check if the weather info is valid
  if [[ -n "$weather_info" ]]; then
    echo "$COUNTRY, $CITY: $weather_info"
  else
    echo "Weather info unavailable for $COUNTRY, $CITY"
  fi
else
  echo "Unable to determine your location"
fi
