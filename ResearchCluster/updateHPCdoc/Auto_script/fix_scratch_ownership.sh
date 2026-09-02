#!/bin/bash
# ------------------------------------------------------------------
# Script: fix_scratch_ownership.sh
# Purpose: For each user folder under /home/users, if the user is in
#          the allowed list, set ownership of /home/users/<user>/scratch
#          to user:grp-user if it exists.
# Usage: sudo ./fix_scratch_ownership.sh
# ------------------------------------------------------------------

USERS_ROOT="/home/users"

# List of users to process (put here the users you want to include)
ALLOWED_USERS=(
    abu_bakar_bin_othman
    aditya_kumar
    ambuj_mehrish
    andy
    anhdung_dinh
    apimuk_sornsaeng
    benjamin_drabkin
    billy_lau
    binbin_chen
    bo_wang
    bo_wang1
    bo_wang2
    brandon_lawrence
    brito_andres
    bryan_tan
    chandler_doloriel
    Changhsi_mong
    chao_liu
    chaoqun_you
    chenxiang_luo
    christopher
    christopher_teo
    chuang_zhang
    chuanhong_liu
    claire_oudea
    clarence_leesheng
    Cornelius_lin
    cucntk
    daniel_chin
    daryll_wong
    deepanway_ghosal
    derong_loh
    desmond_loke
    dong_ke
    ernest_chong
    ernest_chong2
    ernest_chong3
    ernest_chong4
    eugene_hoong
    eugene_ong
    fanyi_meng
    gauthameshwar_s
    goh_jetwei
    guangtao_zeng
    guangtong_li
    guimeng_liu
    guoshun_nan
    hangwee_lee
    hannah_mah
    han_wang
    haolan_he
    haoran2_li
    he_huang
    hossein_mousavi
    hosy_tuyen
    huang_he
    hui_chen
    huiqing_lin
    huiting_gan
    jaredlim
    jia_gong
    jiangyi_wang
    jiasen_chen
    jiaxi_li
    jingyi
    jingyi_xu
    jinquan_ng
    jireh_tan
    junhao_koh
    junting_liu
    keith_low
    kenny_choo
    keshigeyan
    kevin_lawrence
    khiamhee_goh
    kimcuc_nguyen
    kinwai_cheuk
    kritika_johari
    kun_guo
    kwanhui_lim
    lei_cheng
    lei_guo
    lingeng_foo
    litianjiao
    li_xu
    long_he
    marie_siew
    matthieu_demari
    melissa
    menglin_li
    milad_abdollahzadeh
    mingshan
    mingshan_hee
    minhtri_phan
    na_zhao
    ngailam_ho
    ngoctrung_tran
    nguyenanhtuan_hoang
    nguyen_hoang
    nipuni_karumpulli
    nirmal_prakash
    nurul_akhira
    pamela_wang
    panpan_li
    peiyuan_zhang
    pengcheng_wei
    pengfei_wang
    peng_kang
    qihao_zhu
    qing_meng
    qin_you
    qun_song
    rahul_parthasarathy
    ramesh_fernando
    raymond_harrison
    reuben_soh
    roy_lee
    ruhui_zhang
    rui_liu
    sarah_chua
    sean_chenjiale
    shaoxiang_go
    shaun_toh
    shengqiang_zhang
    shengyu_zhang
    shuai_wang
    shukai_ma
    sicong_leng
    siddharth_kumar
    somayeh_ebrahimkhani
    sporia
    srinivas_suyoga
    summer_huang
    tenzin_chan
    tianduo
    tianduo_wang
    tianjiao_li
    tianning_zhang
    tiansi_li
    tianze_yu
    timoth_liu
    timothy_liau
    timothy_liu
    tongjun_shi
    tranlytu_le
    triphan
    tushar_vaidya
    umang_gupta
    user1
    username
    uxuan_tan
    vanessa_tan
    vankhoa_duong
    vanmao_ngo
    varsha_venkatesh
    viethung_tran
    vishal_choudhary
    vovan_tuan
    wanli_yeo
    wenchao_xia
    wenchuan_mu
    wenxiao_zhang
    wenxuan_zhang
    xia_huang
    xianzhi_xianzhi
    xiaobing_sun
    xiaofang_chen
    xing_bo
    xingqiu_he
    xingwei_zhong
    xulin_song
    yan_zhang
    ye_wei
    yinhui_ma
    yining_pan
    yining_zhang
    yong_fang
    yufei_wu
    yuhao_he
    yuhao_wu
    yujia_hu
    yunfeng_fan
    yunqing_zhao
    zaki_masood
    zexian_hong
    zhangsheng_lai
    zhenhao_ng
    zhibo_huang
    zhiqiang_hu
    zhonghao_yang
    zhuochen_yu
    zihan
    zihan_c
    zihan_chen
    ziqi_jin
    zong_tianqi
    zongyang_du
)

# Function to check if a user is in the allowed list
is_allowed_user() {
  local user="$1"
  for u in "${ALLOWED_USERS[@]}"; do
    if [ "$u" == "$user" ]; then
      return 0
    fi
  done
  return 1
}

# Main loop
for user_dir in "$USERS_ROOT"/*; do
  [ -d "$user_dir" ] || continue
  USER_NAME=$(basename "$user_dir")
  
  # If user not in allowed list, skip
  if ! is_allowed_user "$USER_NAME"; then
    echo "Skipping user (not in allowed list): $USER_NAME"
    continue
  fi

  SCRATCH_LINK="$user_dir/scratch"

  # Check if scratch link or directory exists
  if [ -e "$SCRATCH_LINK" ]; then
    echo "Fixing ownership for: $SCRATCH_LINK"
    chown -h "${USER_NAME}:grp-${USER_NAME}" "$SCRATCH_LINK" 2>/dev/null || \
      echo "Warning: cannot chown symlink $SCRATCH_LINK"
    TARGET_DIR=$(readlink -f "$SCRATCH_LINK")
    if [ -d "$TARGET_DIR" ]; then
      chown "${USER_NAME}:grp-${USER_NAME}" "$TARGET_DIR" 2>/dev/null || \
        echo "Warning: cannot chown directory $TARGET_DIR"
    else
      echo "Skipped: target directory $TARGET_DIR not found"
    fi
  else
    echo "No scratch link found for user: $USER_NAME"
  fi

done

echo "Done."

