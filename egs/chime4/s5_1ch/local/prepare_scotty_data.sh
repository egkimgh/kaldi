#!/bin/bash


. ./path.sh
. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
           ## This relates to the queue.

# Config:
nj=20
stage=0 # resume training with --stage=N

. utils/parse_options.sh || exit 1;

# This is a shell script, but it's recommended that you run the commands one by
# one by copying and pasting into the shell.

if [ $# -ne 1 ]; then
  printf "\nUSAGE: %s <feature>\n\n" `basename $0`
  echo "The argument specifies the type of feature <mfcc|fbank|spectrogram|fmllr>"
  exit 1;
fi

# set chime4 data
chime4_data=/DB/CHiME4/CHiME3 # specifies the directory of wav files"
feat=$1
wavdir=scotty

# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

set_list="2"
#ch_combi="1:1,3 2:4,6 3:1,4 4:3,6"
mic_pair_list="4,6"
env_list="simu real"
chs="0 1"

if [ $stage -le 1 ]; then
  for mic_pair in $mic_pair_list; do
    local/simu_scotty_chime4_data_prep.sh $chime4_data 2 $mic_pair
    local/real_scotty_chime4_data_prep.sh $chime4_data 2 $mic_pair
  done
fi

# featdir should be some place with a largish disk where you
# want to store features.
if [ $feat == "mfcc" ]; then
  featcmd=steps/make_mfcc
  featopt=
  featdir=mfcc
elif [ $feat == "fbank" ]; then
  featcmd=steps/make_fbank
  featopt=
  featdir=fbank
elif [ $feat == "spectrogram" ]; then
  featcmd=local/make_spectrogram
  featopt=
  featdir=spect
else
  echo "Usage : compute_feature <mfcc|fbank|spectrogram|fmllr>" ; exit 1
fi

if [ $stage -le 2 ]; then
  tasks=""
  for env in $env_list; do
   for set in $set_list; do
      dir_tr=tr05_${env}_scotty_set${set}
      dir_dt=dt05_${env}_scotty_set${set}
      dir_et=et05_${env}_scotty_set${set}

      tasks="${tasks} $dir_tr $dir_dt $dir_et"
    done
  done
  echo $tasks

  for ch in $chs; do
    for x in $tasks; do
      dir="$featdir/$x/ch${ch}"
      echo "extracting features...${dir}"
      $featcmd.sh --nj $nj --cmd "$train_cmd" --channel $ch data/$x $dir/log $dir
      steps/compute_cmvn_stats.sh data/$x $featdir/log $dir
      #compute-cmvn-stats --spk2utt=ark:data/$x/spk2utt scp:data/$x/$ch/feats.scp ark:$dir/cmvn_speaker.ark
      mv data/$x/feats{.scp,.ch${ch}.scp}
      mv data/$x/cmvn{.scp,.ch${ch}.scp}
    done
  done
fi

# make mixed training set from real and simulation training data
# multi = simu + real
# Note that we are combining enhanced training data with noisy training data
if [ $stage -le 3 ]; then
  for set in $set_list; do
    for task in tr05 dt05 et05; do
      outdir=${task}_scotty_set${set}
      for ch in $chs; do
        echo $outdir
        cp -v data/${task}_simu_scotty_set${set}/feats{.ch${ch}.scp,.scp} 
        cp -v data/${task}_real_scotty_set${set}/feats{.ch${ch}.scp,.scp} 
        cp -v data/${task}_simu_scotty_set${set}/cmvn{.ch${ch}.scp,.scp} 
        cp -v data/${task}_real_scotty_set${set}/cmvn{.ch${ch}.scp,.scp} 
        utils/combine_data.sh data/$outdir data/${task}_simu_scotty_set${set} data/${task}_real_scotty_set${set}
        #cp -v data/$outdir/feats{.scp,.ch${ch}.scp}
        #cp -v data/$outdir/cmvn{.scp,.ch${ch}.scp}
        cp -v data/$outdir/feats.scp data/feats.ch${ch}.scp
        cp -v data/$outdir/cmvn.scp data/cmvn.ch${ch}.scp
      done
      mv -v data/feats.ch0.scp data/$outdir
      mv -v data/cmvn.ch0.scp data/$outdir
      mv -v data/feats.ch1.scp data/$outdir
      mv -v data/cmvn.ch1.scp data/$outdir
      steps/compute_cmvn_stats.sh data/$outdir data/$outdir/log data/$outdir
    done
  done
fi

