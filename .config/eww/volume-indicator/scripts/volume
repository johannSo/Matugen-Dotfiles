#!/bin/bash

volume=$(pamixer --get-volume)
prev_volume=$volume

eww="eww -c $HOME/.config/eww/volume-indicator"

$eww open volume-indicator

while :
do
  sleep 0.1
   volume=$(pamixer --get-volume)

   if [ "$volume" != "$prev_volume" ]
   then
       # Звук изменился, выполняем команду для скрытия индикатора звука
       $eww update volume_hidden=true
       echo true
       prev_volume=$volume
       sleep 1

       # Проверяем, как долго идет изменение звука
       new_volume=$(pamixer --get-volume)
       if [ "$new_volume" != "$prev_volume" ]
       then
           # Изменение звука продолжается, ничего не делаем
           continue
       else
           # Изменение звука прекратилось, выполняем команду для отображения индикатора звука
           $eww update volume_hidden=false
           echo false
           prev_volume=$volume
       fi
   fi
done
