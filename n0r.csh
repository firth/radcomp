# Special script for gridding the NEXRAD composites
# set echo

setenv STARTTIME `date -u +'%Y%m%d%H%M%S'`

setenv RAD /mnt/nexrad3/nexrad/
setenv PATH "${PATH}:/home/meteor_ldm/bin"
setenv NA_OS linux64
setenv GEMTBL gempak/tables
setenv GEMPARM gempak/param
setenv GEMPAKHOME gempak
setenv CONFIGDIR gempak/config
setenv GEMERR gempak/error
setenv GEMPDF gempak/pdf

set yy="`echo $1 | cut -c 3-4`"
set gtime="$yy$2$3/$4$5"
set ftime="$1$2$3$4$5"

set lut="iem_n0r.tbl"
set radmode="PC"
set routes="acr"
set realtime="t"
if ($# == 7) then
  set realtime="f"
  set routes="a"
endif
set fp="n0r_$$.png"

# Create N0R from N0Q as N0R is no longer generated by NWS
python scripts/pseudo_n0r.py $ftime $fp || exit

# Convert it to TIF for algorithm work
magick -compress none $fp n0r_$$_in.tif >& /dev/null

# Convert it to TIF for algorithm work
magick -compress none data/eet_${ftime}.gif net_$$_in.tif

# Clean it! 
python gdal_clean.py $$ $1$2$3$4$5
magick -compress none test_$$.png n0r_$$_out.tif >& /dev/null
pqinsert -p "gis ${routes} ${ftime} gis/images/4326/USCOMP/n0r_ GIS/uscomp/n0r_${ftime}.png png" test_$$.png

# Also insert the world file, so that the archive gets it!
python n0r_gentfw.py ${ftime} n0r
pqinsert -i -p "gis ${routes} ${ftime} gis/images/4326/USCOMP/n0r_ GIS/uscomp/n0r_${ftime}.wld wld" n0r${ftime}.tfw

if ($realtime == "t") then
  # Generate GeoTIFF
  geotifcp -e n0r.tfw n0r_$$_out.tif n0r_$$_out.gtif >& /dev/null

  # Generate google maps variant
  cp n0r.tfw n0r_$$_out.tfw
  gdalwarp  -q -s_srs EPSG:4326 -t_srs EPSG:3857 n0r_$$_out.tif google_n0r_$$_out.tif
  rm -f n0r_$$_out.tfw

  gzip -c n0r_$$_out.tif > n0r_$$_out.tif.Z
  pqinsert -p "gis r ${ftime} gis/images/4326/USCOMP/n0r_ bogus tif.Z" n0r_$$_out.tif.Z

  gzip -c google_n0r_$$_out.tif > google_n0r_$$_out.tif.Z
  pqinsert -p "gis r ${ftime} gis/images/900913/USCOMP/n0r_ bogus tif.Z" google_n0r_$$_out.tif.Z

  gzip -c n0r_$$_out.gtif > n0r_$$_out.gtif.Z
  pqinsert -p "gis r ${ftime} gis/images/4326/USCOMP/n0r_ bogus gtif.Z" n0r_$$_out.gtif.Z

  # Save a file locally for rotation
  cd tmp/
  foreach i (10 9 8 7 6 5 4 3 2 1 0)
    set j = `echo "${i} + 1" | bc `
    if ( -f n0r_${i}.gif ) then
      mv n0r_${i}.gif n0r_${j}.gif
    else
      # We have a missing file, so try something desperate
      set k = `echo "${i} - 1" | bc `
      echo "Missing n0r_${i}.gif, copying n0r_${k}.gif"
      cp n0r_${k}.gif n0r_${i}.gif
    endif
  end
  magick ../test_$$.png n0r_0.gif
  gifsicle -U --transparent "#000" --loopcount=0 --delay=100 n0r_11.gif n0r_10.gif  n0r_9.gif n0r_8.gif n0r_7.gif n0r_6.gif n0r_5.gif n0r_4.gif n0r_3.gif n0r_2.gif n0r_1.gif n0r_0.gif  -o anim.gif >& /dev/null
  pqinsert -p "gis c ${ftime} gis/images/4326/USCOMP/n0r_anim_large.gif bogus gif" anim.gif
  gifsicle -U --resize 600x260 --transparent "#000" --loopcount=0 --delay=100 n0r_11.gif n0r_10.gif  n0r_9.gif n0r_8.gif n0r_7.gif n0r_6.gif n0r_5.gif n0r_4.gif n0r_3.gif n0r_2.gif n0r_1.gif n0r_0.gif  -o small.gif >& /dev/null
  pqinsert -p "gis c ${ftime} gis/images/4326/USCOMP/n0r_anim_600x260.gif bogus gif" small.gif
  gifsicle -U --resize 1200x520 --transparent "#000" --loopcount=0 --delay=100 n0r_11.gif n0r_10.gif  n0r_9.gif n0r_8.gif n0r_7.gif n0r_6.gif n0r_5.gif n0r_4.gif n0r_3.gif n0r_2.gif n0r_1.gif n0r_0.gif  -o small.gif >& /dev/null
  pqinsert -p "gis c ${ftime} gis/images/4326/USCOMP/n0r_anim_1200x520.gif bogus gif" small.gif
  
  cd ../
endif

rm -f net_$$_in.gtif
rm -f n0r${ftime}.tfw test_$$.png net_$$_in.tif n0r_$$_in.tif n0r_$$_out.tif n0r_$$_out.tif.Z n0r_$$_out.gtif.Z google_n0r_$$_out.tif.Z google_n0r_$$_out.tif n0r_$$_out.gtif

python scripts/create_metadata.py US $1 $2 $3 $4 $5 N0R $STARTTIME $$

rm -f logs/nex2img_US_N0R_$$.log n0r_$$.png
