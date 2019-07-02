#!/bin/bash

steps/align_fmllr.sh --nj 30 data/tr05_multi_blstm_gev data/lang exp/tri3b_tr05_multi_blstm_gev exp/tri3b_tr05_multi_blstm_gev_ali_train
steps/align_fmllr.sh --nj 4 data/dt05_multi_blstm_gev data/lang exp/tri3b_tr05_multi_blstm_gev exp/tri3b_tr05_multi_blstm_gev_ali_dev
steps/align_fmllr.sh --nj 4 data/et05_multi_blstm_gev data/lang exp/tri3b_tr05_multi_blstm_gev exp/tri3b_tr05_multi_blstm_gev_ali_test
