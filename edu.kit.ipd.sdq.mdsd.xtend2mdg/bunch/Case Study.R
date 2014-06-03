################
# PCMEvents2PCM
################

# class-level (HC_100-90-10-OFF W4 Lib)
# # MQ  	Prec.   Recall  EdgeSim MeCl
# 1	3.871	34.938	72.581	72.28   -160
# 2	2.652	23.391	73.871	79.89	  -100
# 3	3.594	33.465	81.935	80.43	  -140
# 4	2.007	22.201	76.129	76.08	  -120
# 5	2.861	28.090	80.645	83.69	  -80

# is expected to be superior than

# methods-only (HC_100-90-10-OFF W5)
# # MQ		Prec.   Recall  EdgeSim MeCl
# 0	3.399	16.195	40.645  49.45   -1380
# 1	4.470	14.395	24.194  46.73   -1260
# 2	3.740	17.169	36.774	61.95   -1040
# 3	4.354	21.683	43.226	53.80   -1340
# 4	6.743	28.342	34.194	52.17   -1320
#[5	4.157	15.975	33.548	44.56   -1440]

# Two-sided Wilcox test to reveal significance (confidence)
# One-sided Wilcox test to give confidence for direction
wilcox.test(c(3.871, 2.652, 3.594, 2.007, 2.861), c(3.399, 4.470, 3.740, 4.354, 6.743))
wilcox.test(c(3.871, 2.652, 3.594, 2.007, 2.861), c(3.399, 4.470, 3.740, 4.354, 6.743), alternative="less")
# => MQ is less good (p=0.056) because class-level has been optimized for method AND class dependencies
wilcox.test(c(34.938, 23.391, 33.465, 22.201, 28.090), c(16.195, 14.395, 17.169, 21.683, 28.342))
wilcox.test(c(34.938, 23.391, 33.465, 22.201, 28.090), c(16.195, 14.395, 17.169, 21.683, 28.342), alternative="greater")
# => Precision insignificantly different (p=0.056)
wilcox.test(c(72.581, 73.871, 81.935, 76.129, 80.645), c(40.645, 24.194, 36.774, 43.226, 34.194))
wilcox.test(c(72.581, 73.871, 81.935, 76.129, 80.645), c(40.645, 24.194, 36.774, 43.226, 34.194), alternative="greater")
# => Recall significantly different (p=0.008) i.e. better (p=0.004)
wilcox.test(c(72.28, 79.89, 80.43, 76.08, 83.69), c(49.45, 46.73, 61.95, 53.80, 52.17))
wilcox.test(c(72.28, 79.89, 80.43, 76.08, 83.69), c(49.45, 46.73, 61.95, 53.80, 52.17), alternative="greater")
# => EdgeSim significantly different (p=0.008) and better
wilcox.test(c(-160, -100, -140, -120, -80), c(-1380, -1260, -1040, -1340, -1320))
wilcox.test(c(-160, -100, -140, -120, -80), c(-1380, -1260, -1040, -1340, -1320), alternative="greater")
# => MeCl significantly different (p=0.008) and better

################
# PCM2SimuCom
################

# class-level (HC_100-90-10-OFF W6 Lib)
# # MQ      Prec.   Recall  EdgeSim MeCl
# 0 10.741  48.655  59.277  88.63   -1380 mdg0L1 user-directed
# 1 9.078   47.465  60.854  87.67   -1680 mdg1L2 user-directed
# 2 6.681   32.928  46.066  86.53   -2160 mdg2L2 user-directed
# 3 6.746   39.310  62.026  86.62   -1780 mdg3 agglomerative
# 4 5.640   24.431  61.858  87.39   -1640 mdg4 agglomerative

# is expected to be superior than

# methods-only (HC_100-90-10-OFF W5)
# # MQ  	Prec.   Recall  EdgeSim MeCl
# 0 4.896 13.259  29.836  50.63   -6600
# 1 2.362 13.522  20.449  58.78   -4460
# 2 1.541 9.984   27.554  56.32   -5740
# 3 4.641 14.032  16.860  55.34   -5620
# 4 9.715 16.070  18.351  50.63   -6720

wilcox.test(c(10.741, 9.078, 6.681, 6.746, 5.640), c(4.896, 2.362, 1.541, 4.641, 9.715))
wilcox.test(c(10.741, 9.078, 6.681, 6.746, 5.640), c(4.896, 2.362, 1.541, 4.641, 9.715), alternative="greater")
# => MQ computed on graph w/o model elements is INsignificantly better (p=0.09524) for class-level clustering
wilcox.test(c(48.655, 47.465, 32.928, 39.310, 24.431), c(13.259, 13.522, 9.984, 14.032, 16.070))
wilcox.test(c(48.655, 47.465, 32.928, 39.310, 24.431), c(13.259, 13.522, 9.984, 14.032, 16.070), alternative="greater")
# => Precision is significantly higher (p=0.007937)
wilcox.test(c(59.277, 60.854, 46.066, 62.026, 61.858), c(29.836, 20.449, 27.554, 16.860, 18.351))
wilcox.test(c(59.277, 60.854, 46.066, 62.026, 61.858), c(29.836, 20.449, 27.554, 16.860, 18.351), alternative="greater")
# => Recall is significantly higher (p=0.007937)
wilcox.test(c(88.63, 87.67, 86.53, 86.62, 87.39), c(50.63, 58.78, 56.32, 55.34, 50.63))
wilcox.test(c(88.63, 87.67, 86.53, 86.62, 87.39), c(50.63, 58.78, 56.32, 55.34, 50.63), alternative="greater")
# => EdgeSim is significantly better (p=0.01193)
wilcox.test(c(-1380, -1680, -2160, -1780, -1640), c(-6600, -4460, -5740, -5620, -6720))
wilcox.test(c(-1380, -1680, -2160, -1780, -1640), c(-6600, -4460, -5740, -5620, -6720), alternative="greater")
# => MeCl is significantly better (p=0.007937)
