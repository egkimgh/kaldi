#!/bin/bash

cmd_dir="`pwd`"
echo $cmd_dir
chime4_list_dir="/internal/data/CHiME4/CHiME3/data/annotations" # *_1ch_track.list, *_2ch_track_list
chime4_list="dt05_real dt05_simu et05_real et05_simu"

chime4_1ch_dir="/internal/data/CHiME4/CHiME3/data/audio/16kHz/isolated_1ch_track"
chime4_2ch_dir="/internal/data/CHiME4/CHiME3/data/audio/16kHz/isolated_2ch_track"

mkdir -p $chime4_1ch_dir
cd $chime4_1ch_dir
# for 1ch
for flist in $chime4_list; do
	fn_list="$chime4_list_dir/${flist}_1ch_track.list"
	cmd1="cat $fn_list" 
	cmd2="./make_file_link.sh"
	echo "$cmd1 | $cmd2";
	$cmd1 | $cmd_dir/$cmd2
done
cd -

# for 2ch
mkdir -p $chime4_2ch_dir
cd $chime4_2ch_dir
for flist in $chime4_list; do
	fn_list="$chime4_list_dir/${flist}_2ch_track.list"
	cmd1="cat $fn_list"
	cmd2="tr \" \" \"\n\""
	cmd3="./make_file_link.sh"
	echo "$cmd1 | $cmd2 | $cmd3";
	$cmd1 | tr " " "\n" | $cmd_dir/$cmd3;
done
cd -
