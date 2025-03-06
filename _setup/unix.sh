#!/bin/sh
# SETUP FOR MAC AND LINUX SYSTEMS!!!
# REMINDER THAT YOU NEED HAXE INSTALLED PRIOR TO USING THIS
# https://haxe.org/download
cd ..
echo Makking the main haxelib and setuping folder in same time..
mkdir ~/haxelib && haxelib setup ~/haxelib
echo Installing dependencies...
echo This might take a few moments depending on your internet speed.
haxelib install lime 8.1.2 --quiet
haxelib install openfl 9.3.3 --quiet
haxelib install flixel 5.5.0 --quiet
haxelib install flixel-addons 3.2.2 --quiet
haxelib git moonchart https://github.com/MaybeMaru/moonchart --quiet
haxelib git hscript-iris https://github.com/crowplexus/hscript-iris --quiet
haxelib install hxdiscord_rpc 1.2.4 --quiet --skip-dependencies
haxelib install hxvlc 1.9.2 --quiet --skip-dependencies
haxelib install hxjson5 --quiet
haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp 54af892be2ca4c63988c99c9c524431af6c6f036 --quiet
haxelib git flxanimate https://github.com/Dot-Stuff/flxanimate 768740a56b26aa0c072720e0d1236b94afe68e3e --quiet
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit 1906c4a96f6bb6df66562b3f24c62f4c5bba14a7 --quiet
haxelib git funkin.vis https://github.com/FunkinCrew/funkVis 22b1ce089dd924f15cdc4632397ef3504d464e90 --quiet
haxelib git grig.audio https://gitlab.com/haxe-grig/grig.audio.git cbf91e2180fd2e374924fe74844086aab7891666 --quiet
echo Finished!
