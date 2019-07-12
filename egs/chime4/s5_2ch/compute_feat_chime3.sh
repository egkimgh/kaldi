#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
. ./path.sh ## Source the tools/utils (import the queue.pl)

feat=$1

[ -z $feat ] && echo "Usage : compute_feature <mfcc|fbank|spectrogram|fmllr>" && exit 1

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
elif [ $feat == "fmllr" ]; then
  featcmd=steps/nnet/make_fmllr_feats
  featopt=
  featdir=data-fmllr-tri3b
  gmmdir=exp/tri3b_tr05_multi_noisy
else
  echo "Usage : compute_feature <mfcc|fbank|spectrogram|fmllr>" ; exit 1
fi

for chunk in tr05_multi_blstm_gev dt05_multi_blstm_gev et05_simu_blstm_gev et05_real_blstm_gev; do
  dir=$featdir/$chunk

  if [ $feat == "fmllr" ]; then
    $featcmd.sh --nj 4 --cmd "$train_cmd" \
        --transform-dir $gmmdir/decode_tgpr_5k_$chunk \
            $dir data/$chunk $gmmdir $dir/log $dir || exit 1
  else
    $featcmd.sh --nj 4 --cmd "$train_cmd" \
            data/$chunk $dir/log $dir || exit 1
  fi

  echo 

  compute-cmvn-stats --spk2utt=ark:data/$chunk/spk2utt scp:data/$chunk/feats.scp ark:$dir/cmvn_speaker.ark
  echo

done
