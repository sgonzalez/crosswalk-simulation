#!/bin/bash

echo -ne "pacman (0) or apt-get (1): "
read CHOICE


if [ $CHOICE -eq "0" ]
then
  sudo pacman -S sfml
else
  sudo apt-get install libsfml-dev
fi


exit 0
