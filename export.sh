#!/bin/sh

mkdir -p export/SCS.x11/
mkdir -p export/SCS.HTML/
mkdir -p export/SCS.mac/
mkdir -p export/SCS.win/

~/opt/Godot_v3.0.2-stable_x11.64 --export "Linux/X11" export/SCS.x11/SCS.x86_64
~/opt/Godot_v3.0.2-stable_x11.64 --export "HTML5" export/SCS.HTML/SCS.html
~/opt/Godot_v3.0.2-stable_x11.64 --export "Mac OSX" export/SCS.mac/SCS.zip
~/opt/Godot_v3.0.2-stable_x11.64 --export "Windows Desktop" export/SCS.win/SCS.exe

