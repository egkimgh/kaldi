#!/bin/bash

set -e

# Copyright 2009-2012  Microsoft Corporation  Johns Hopkins University (Author: Daniel Povey)
# Apache 2.0.

# This is modified from the script in standard Kaldi recipe to account
# for the way the WSJ data is structured on the Edinburgh systems.
# - Arnab Ghoshal, 29/05/12

# Modified from the script for CHiME2 baseline
# Shinji Watanabe 02/13/2015
# Modified to use data of six channels
# Szu-Jui Chen 09/29/2017

# Config:
eval_flag=true # make it true when the evaluation data are released
create_wav_flag=true 

echo "$0 $@"  # Print the command line for logging

. utils/parse_options.sh || exit 1;

if [ $# -ne 3 ]; then
  printf "\nUSAGE: %s <corpus-directory> <set #> <channel sequence>\n\n" `basename $0`
  echo "The argument should be a the top-level Chime4 directory."
  echo "It is assumed that there will be a 'data' subdirectory"
  echo "within the top-level corpus directory."
  echo "ch # : channel number sequence, eg) 1,3"
  exit 1;
fi

set=$2
ch=$3

[ -z "$set" ] && echo "Missing # of training set, they were used in training!" && exit 1
[ -z $ch ] && echo "Missing channel number !" && exit 1

chs="${ch//,/ }"
echo "mic array : $ch --> $chs"

audio_dir=$1/data/audio/16kHz/isolated
trans_dir=$1/data/transcriptions

echo "extract channels (CH[${ch}].wav) for noisy data"

wavdir=`pwd`/scotty
dir=`pwd`/data/local/data
mkdir -p $dir $wavdir
local=`pwd`/local
utils=`pwd`/utils
odir=`pwd`/data

. ./path.sh # Needed for KALDI_ROOT

#check is sox on the path
which sox &>/dev/null
! [ $? -eq 0 ] && echo "sox: command not found" && exit 1;

if $eval_flag; then
  list_set="tr05 dt05 et05"
else
  list_set="tr05 dt05"
fi

# Create 2-ch stereo data for scotty
if $create_wav_flag; then

  for src in $list_set; do
		cd $wavdir
		mkdir -p $wavdir/set${set}
		
		ch1=`echo ${ch} | awk -F"," '{ print $1}'`
		find $audio_dir -name "*CH[${ch1}].wav" | grep "${src}_bus_simu\|${src}_caf_simu\|${src}_ped_simu\|${src}_str_simu" | sort -u > ${src}_simu_scotty_set${set}_mic1.flist
		n_ch1=`cat ${src}_simu_scotty_set${set}_mic1.flist | wc -l`
		
		ch2=`echo ${ch} | awk -F"," '{ print $2}'`
		find $audio_dir -name "*CH[${ch2}].wav" | grep "${src}_bus_simu\|${src}_caf_simu\|${src}_ped_simu\|${src}_str_simu" | sort -u > ${src}_simu_scotty_set${set}_mic2.flist
		n_ch2=`cat ${src}_simu_scotty_set${set}_mic2.flist | wc -l`
		
		echo "${ch1}:${n_ch1}, ${ch2}:${n_ch2}"
		
		[ $n_ch1 -ne $n_ch2 ] && echo "Error ! : the number of files are different between ${ch1}(${n_ch1}) and ${ch2}(${n_ch2})" && exit 1
		
		cmd="sed s/CH${ch1}/SET${set}/"
		cat ${src}_simu_scotty_set${set}_mic1.flist | awk -F"/" '{print $NF}' | $cmd > ${src}_simu_scotty_set${set}.flist
		
		paste -d" " ${src}_simu_scotty_set${set}_mic1.flist ${src}_simu_scotty_set${set}_mic2.flist ${src}_simu_scotty_set${set}.flist > ${src}_simu_scotty_set${set}_pair.flist
		
		while IFS= read -r line
		do
		  ## take some action on $line
		  f1=`echo ${line} | awk -F" " '{print $1}'`
		  f2=`echo ${line} | awk -F" " '{print $2}'`
		  f3=`echo ${line} | awk -F" " '{print $3}'`
		  type_dir=`dirname ${f1} | awk -F"/" '{print $NF}'`
      mkdir -p ${wavdir}/set${set}/${type_dir}
		  cmd="sox -S ${f1} ${f2} --channels 2 --combine merge ${wavdir}/set${set}/${type_dir}/${f3}"
		  #echo $cmd; break
      $cmd
		done < "${src}_simu_scotty_set${set}_pair.flist"
  done

fi

###
###
###
if $eval_flag; then
  list_set="tr05_simu_scotty_set${set} dt05_simu_scotty_set${set} et05_simu_scotty_set${set}"
else
  list_set="tr05_simu_scotty_set${set} dt05_simu_scotty_set${set}"
fi

cd $dir

scotty_dir=${wavdir}/set${set}
echo $scotty_dir
find $scotty_dir -name "*.wav" | grep 'tr05_bus_simu\|tr05_caf_simu\|tr05_ped_simu\|tr05_str_simu' | sort -u > tr05_simu_scotty_set${set}.flist
find $scotty_dir -name "*.wav" | grep 'dt05_bus_simu\|dt05_caf_simu\|dt05_ped_simu\|dt05_str_simu' | sort -u > dt05_simu_scotty_set${set}.flist
if $eval_flag; then
  find $scotty_dir -name "*.wav" | grep 'et05_bus_simu\|et05_caf_simu\|et05_ped_simu\|et05_str_simu' | sort -u > et05_simu_scotty_set${set}.flist
fi

# make a dot format from json annotation files
cp $trans_dir/dt05_simu.dot_all dt05_simu.dot
if $eval_flag; then
  cp $trans_dir/et05_simu.dot_all et05_simu.dot
fi

# make a scp file from file list
for x in $list_set; do
  cat $x.flist | awk -F'[/]' '{print $NF}'| sed -e 's/\.wav/_SIMU/' > ${x}_wav.ids
  paste -d" " ${x}_wav.ids $x.flist | sort -k 1 > ${x}_wav.scp
done

# make a transcription from dot
# simulation training data extract dot file from original WSJ0 data
# since it is generated from these data
if [ ! -e dot_files.flist ]; then
  echo "Could not find $dir/dot_files.flist files, first run local/clean_wsj0_data_prep.sh";
  exit 1;
fi
cat tr05_simu_scotty_set${set}_wav.scp | awk -F'[_]' '{print $2}' | tr '[A-Z]' '[a-z]' \
  | $local/find_noisy_transcripts.pl dot_files.flist | cut -f 2- -d" " > tr05_simu_scotty.txt
cat tr05_simu_scotty_set${set}_wav.scp | cut -f 1 -d" " > tr05_simu_scotty.ids
paste -d" " tr05_simu_scotty.ids tr05_simu_scotty.txt | sort -k 1 > tr05_simu_scotty_set${set}.trans1
# dt05 and et05 simulation data are generated from the CHiME4 booth recording
# and we use CHiME4 dot files
awkcmd="awk {print\$NF\".SET${set}_SIMU\"}"
#echo $awkcmd
cat dt05_simu.dot | sed -e 's/(\(.*\))/\1/' | $awkcmd > dt05_simu_scotty.ids
cat dt05_simu.dot | sed -e 's/(.*)//' > dt05_simu_scotty.txt
paste -d" " dt05_simu_scotty.ids dt05_simu_scotty.txt | sort -k 1 > dt05_simu_scotty_set${set}.trans1

if $eval_flag; then
  cat et05_simu.dot | sed -e 's/(\(.*\))/\1/' | $awkcmd > et05_simu_scotty.ids
  cat et05_simu.dot | sed -e 's/(.*)//' > et05_simu_scotty.txt
  paste -d" " et05_simu_scotty.ids et05_simu_scotty.txt | sort -k 1 > et05_simu_scotty_set${set}.trans1
fi

# Do some basic normalization steps.  At this point we don't remove OOVs--
# that will be done inside the training scripts, as we'd like to make the
# data-preparation stage independent of the specific lexicon used.
noiseword="<NOISE>";
for x in $list_set;do
  cat $x.trans1 | $local/normalize_transcript.pl $noiseword \
  | sort > $x.txt || exit 1;
done

# Make the utt2spk and spk2utt files.
for x in $list_set; do
  cat ${x}_wav.scp | awk -F'_' '{print $1}' > $x.spk
  cat ${x}_wav.scp | awk '{print $1}' > $x.utt
  paste -d" " $x.utt $x.spk > $x.utt2spk
  cat $x.utt2spk | $utils/utt2spk_to_spk2utt.pl > $x.spk2utt || exit 1;
done

# copying data to data/...
for x in $list_set; do
  mkdir -p $odir/$x
  cp ${x}_wav.scp $odir/$x/wav.scp || exit 1;
  cp ${x}.txt     $odir/$x/text    || exit 1;
  cp ${x}.spk2utt $odir/$x/spk2utt || exit 1;
  cp ${x}.utt2spk $odir/$x/utt2spk || exit 1;
done

echo "Data preparation succeeded"

