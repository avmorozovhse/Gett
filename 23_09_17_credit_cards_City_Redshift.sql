SELECT DISTINCT cc.user_gk, cc.bin_number
FROM public.dim_credit_cards_v cc
  JOIN public.dim_users_v du ON du.user_gk = cc.user_gk
WHERE cc.bin_number = 539726 or cc.bin_number = 512762 or cc.bin_number = 545182 or cc.bin_number = 540788
or cc.bin_number = 525689 or cc.bin_number = 520306 or cc.bin_number = 419351 or cc.bin_number = 419349
ORDER BY cc.user_gk
