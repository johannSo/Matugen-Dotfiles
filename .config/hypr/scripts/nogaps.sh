#!/bin/bash

while true; do
    # Получаем информацию о активном рабочем пространстве
    workspace_info=$(hyprctl activeworkspace)

    # Извлекаем количество окон из информации о рабочем пространстве
    window_count=$(echo "$workspace_info" | grep -oP 'windows:\s*\K\d+')

    if (( window_count <= 1 )); then
    hyprctl --batch "\
        keyword general:gaps_in 0;\
        keyword general:gaps_out 0;\
        keyword general:border_size 0"
    else
    hyprctl --batch "\
        keyword general:gaps_in 6;\
        keyword general:gaps_out 12;\
        keyword general:border_size 1"
    fi

    # Ждем 1 секунду перед следующей проверкой
    sleep 0.5
done
