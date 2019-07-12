#!/bin/bash

steps/align_si.sh --nj 30 data/tr05_multi_blstm_gev data/lang exp/tri1_tr05_multi_blstm_gev exp/tri1_tr05_multi_blstm_gev_ali_train
steps/align_si.sh --nj 4 data/dt05_multi_blstm_gev data/lang exp/tri1_tr05_multi_blstm_gev exp/tri1_tr05_multi_blstm_gev_ali_dev
steps/align_si.sh --nj 4 data/et05_simu_blstm_gev data/lang exp/tri1_tr05_multi_blstm_gev exp/tri1_tr05_multi_blstm_gev_ali_test_simu
steps/align_si.sh --nj 4 data/et05_real_blstm_gev data/lang exp/tri1_tr05_multi_blstm_gev exp/tri1_tr05_multi_blstm_gev_ali_test_real
