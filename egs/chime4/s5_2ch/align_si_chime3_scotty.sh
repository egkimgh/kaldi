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
  printf "\nUSAGE: %s <dr>\n\n" `basename $0`
  echo "The argument specifies the name of set e.g) set_1_2 -> {tr05|dt05|et05}_scotty_set_1_2"
  exit 1;
fi

set=$1

cp -v data/tr05_scotty_${set}/feats{.ch0.scp,.scp}
cp -v data/tr05_scotty_${set}/cmvn{.ch0.scp,.scp}
steps/align_si.sh --nj 30 data/tr05_scotty_${set} data/lang exp/tri1_tr05_multi_blstm_gev exp/tri1_tr05_multi_blstm_gev_ali_train_scotty_${set}

cp -v data/dt05_scotty_${set}/feats{.ch0.scp,.scp}
cp -v data/dt05_scotty_${set}/cmvn{.ch0.scp,.scp}
steps/align_si.sh --nj 4 data/dt05_scotty_${set} data/lang exp/tri1_tr05_multi_blstm_gev exp/tri1_tr05_multi_blstm_gev_ali_dev_scotty_${set}

cp -v data/et05_real_scotty_${set}/feats{.ch0.scp,.scp}
cp -v data/et05_real_scotty_${set}/cmvn{.ch0.scp,.scp}
steps/align_si.sh --nj 4 data/et05_real_scotty_${set} data/lang exp/tri1_tr05_multi_blstm_gev exp/tri1_tr05_multi_blstm_gev_ali_test_real_scotty_${set}
