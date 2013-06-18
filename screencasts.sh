wacom_touch() { xsetwacom --set "Wacom Bamboo 16FG 6x8 Finger touch" Touch $1; }
wacom_pen() {
  xsetwacom --set "Wacom Bamboo 16FG 6x8 Pen stylus" Mode $1;
  xsetwacom --set "Wacom Bamboo 16FG 6x8 Pen eraser" Mode $1;
}
wacomP550(){
  xsetwacom set "Wacom PL550 stylus" MapToOutput HEAD-1
  xsetwacom set "Wacom PL550 eraser" MapToOutput HEAD-1
  activeArea="20 20 6144 4608"
  xsetwacom set "Wacom PL550 stylus" "Area" $activeArea
  xsetwacom set "Wacom PL550 stylus" "Area" $activeArea
}
ogv () { recordmydesktop --delay=1 --width=1280 --height=720 -x 195 -y 97 -o $1 --fps=24 --no-cursor ; }
#mov () { ffmpeg -f alsa -i pulse -f x11grab -r 24 -s 1280x720 -i :0.0+195,97+nomouse -acodec pcm_s16le -vcodec libx264 -vpre lossless_ultrafast -threads 0 $1.mov ; }
mov () { ffmpeg -f alsa -i pulse -f x11grab -r 24 -s 1280x720 -i :0.0+195,97 -acodec libmp3lame -ac 1 -ab 128k -vcodec libx264 -vpre lossless_ultrafast -threads 0 $1.mov ; }
OgvToAvi () { mencoder -idx $1.ogv -ovc lavc -lavcopts vcodec=mpeg4:aspect=16/9:vqscale=2:trell:mbd=2 -oac mp3lame -lameopts fast:preset=standard -o $1.avi ;}
OgvToAviAll () { for f in *ogv; do mencoder $f -ovc lavc -lavcopts vcodec=mpeg4:aspect=16/9:vqscale=2:trell:mbd=2 -oac mp3lame -o `basename $f ogv`avi; done ; }




