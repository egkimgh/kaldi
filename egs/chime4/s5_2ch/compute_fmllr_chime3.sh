#!/bin/bash

. ./cmd.sh ## You'll want to change cmd.sh to something that will work on your system.
. ./path.sh ## Source the tools/utils (import the queue.pl)

gmmdir=exp/tri3b_tr05_multi_noisy
fmllrdir=data-fmllr-tri3b
for chunk in tr05_multi_blstm_gev dt05_multi_blstm_gev et05_multi_blstm_gev; do
    dir=$fmllrdir/$chunk
    #steps/nnet/make_fmllr_feats.sh --nj 4 --cmd "$train_cmd" \
    #    --transform-dir $gmmdir/decode_tgpr_5k_$chunk \
    #        $dir data/$chunk $gmmdir $dir/log $dir || exit 1
    #echo 

    compute-cmvn-stats --spk2utt=ark:data/$chunk/spk2utt scp:$dir/feats.scp ark:$dir/cmvn_speaker.ark
    echo

done
