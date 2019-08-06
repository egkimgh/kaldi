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
  printf "\nUSAGE: %s <sets>\n\n" `basename $0`
  echo "The argument specifies the set pair <set1 set2>"
  exit 1;
fi

feat=$1

# Set bash to 'debug' mode, it will exit on :
# -e 'error', -u 'undefined variable', -o ... 'error in pipeline', -x 'print commands',
set -e
set -u
set -o pipefail

set_list="1,2"
chs="0 1"

# make mixed training set from real and simulation training data
# multi = simu + real
# Note that we are combining enhanced training data with noisy training data
if [ $stage -le 0 ]; then
  set1=`echo ${set_list} | awk -F"," '{ print $1}'`
  set2=`echo ${set_list} | awk -F"," '{ print $2}'`
    for task in tr05 dt05 et05_real; do
      outdir=${task}_scotty_set_${set1}_${set2}
      for ch in $chs; do
        echo $outdir
        cp -v data/${task}_scotty_set${set1}/feats{.ch${ch}.scp,.scp} 
        cp -v data/${task}_scotty_set${set1}/feats{.ch${ch}.scp,.scp} 
        cp -v data/${task}_scotty_set${set2}/cmvn{.ch${ch}.scp,.scp} 
        cp -v data/${task}_scotty_set${set2}/cmvn{.ch${ch}.scp,.scp} 
        utils/combine_data.sh data/$outdir data/${task}_scotty_set${set1} data/${task}_scotty_set${set2}
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
fi

