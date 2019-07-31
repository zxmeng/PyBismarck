# PyBismarck

test_bismarck=# SELECT dense_logit('forest', 1, 54);
NOTICE:  #tuples: 581012
NOTICE:  A shuffled table __bismarck_shuffled_forest_1 is created for training
NOTICE:  #iter: 1, loss value: 402721.578727603
NOTICE:  #iter: 2, loss value: 402716.329899665
NOTICE:  #iter: 3, loss value: 402711.083195452
NOTICE:  #iter: 4, loss value: 402705.838622673
NOTICE:  #iter: 5, loss value: 402700.596189152
NOTICE:  #iter: 6, loss value: 402695.355902656
NOTICE:  #iter: 7, loss value: 402690.117770974
NOTICE:  #iter: 8, loss value: 402684.88180194
NOTICE:  #iter: 9, loss value: 402679.648003374
NOTICE:  #iter: 10, loss value: 402674.416383105
NOTICE:  #iter: 11, loss value: 402669.186948975
NOTICE:  #iter: 12, loss value: 402663.959708864
NOTICE:  #iter: 13, loss value: 402658.734670655
NOTICE:  #iter: 14, loss value: 402653.511842215
NOTICE:  #iter: 15, loss value: 402648.291231446
NOTICE:  #iter: 16, loss value: 402643.072846269
NOTICE:  #iter: 17, loss value: 402637.856694615
NOTICE:  #iter: 18, loss value: 402632.642784379
NOTICE:  #iter: 19, loss value: 402627.431123562
NOTICE:  #iter: 20, loss value: 402622.221720118
 dense_logit 
-------------
 
(1 row)

Time: 1786707.119 ms (29:46.707)

test_bismarck=# SELECT dense_svm('forest', 1, 54);
NOTICE:  #tuples: 581012
NOTICE:  A shuffled table __bismarck_shuffled_forest_1 is created for training
NOTICE:  #iter: 1, loss value: 581024.141658131
NOTICE:  #iter: 2, loss value: 581036.283316249
NOTICE:  #iter: 3, loss value: 581048.424974372
NOTICE:  #iter: 4, loss value: 581060.566632522
NOTICE:  #iter: 5, loss value: 581072.708290633
NOTICE:  #iter: 6, loss value: 581084.849948748
NOTICE:  #iter: 7, loss value: 581096.991606881
NOTICE:  #iter: 8, loss value: 581109.133265007
NOTICE:  #iter: 9, loss value: 581121.274923143
NOTICE:  #iter: 10, loss value: 581133.416581251
NOTICE:  #iter: 11, loss value: 581145.558239376
NOTICE:  #iter: 12, loss value: 581157.69989751
NOTICE:  #iter: 13, loss value: 581169.841555629
NOTICE:  #iter: 14, loss value: 581181.983213739
NOTICE:  #iter: 15, loss value: 581194.124871875
NOTICE:  #iter: 16, loss value: 581206.266529985
NOTICE:  #iter: 17, loss value: 581218.408188091
NOTICE:  #iter: 18, loss value: 581230.549846268
NOTICE:  #iter: 19, loss value: 581242.691504383
NOTICE:  #iter: 20, loss value: 581254.833162539
 dense_svm 
-----------
 
(1 row)

Time: 1617390.804 ms (26:57.391)

test_bismarck=# SELECT sparse_logit('dblife', 22, 41270);
NOTICE:  #tuples: 16240
NOTICE:  A shuffled table __bismarck_shuffled_dblife_22 is created for training
NOTICE:  #iter: 1, loss value: 11209.770839039
NOTICE:  #iter: 2, loss value: 11181.6557389339
NOTICE:  #iter: 3, loss value: 11163.0481153546
NOTICE:  #iter: 4, loss value: 11149.6786247935
NOTICE:  #iter: 5, loss value: 11139.5262740648
NOTICE:  #iter: 6, loss value: 11131.520571828
NOTICE:  #iter: 7, loss value: 11125.0372713122
NOTICE:  #iter: 8, loss value: 11119.6842405054
NOTICE:  #iter: 9, loss value: 11115.2005509634
NOTICE:  #iter: 10, loss value: 11111.4045091108
NOTICE:  #iter: 11, loss value: 11108.1648833724
NOTICE:  #iter: 12, loss value: 11105.3840037742
NOTICE:  #iter: 13, loss value: 11102.9873385081
NOTICE:  #iter: 14, loss value: 11100.9167972086
NOTICE:  #iter: 15, loss value: 11099.1262770333
NOTICE:  #iter: 16, loss value: 11097.5786112308
NOTICE:  #iter: 17, loss value: 11096.2434241782
NOTICE:  #iter: 18, loss value: 11095.0955893805
NOTICE:  #iter: 19, loss value: 11094.1140987896
NOTICE:  #iter: 20, loss value: 11093.2812190469
 sparse_logit 
--------------
 
(1 row)

Time: 5916034.590 ms (01:38:36.035)

test_bismarck=# SELECT sparse_svm('dblife', 22, 41270);
NOTICE:  #tuples: 16240
NOTICE:  A shuffled table __bismarck_shuffled_dblife_22 is created for training
NOTICE:  #iter: 1, loss value: 16223.1009685297
NOTICE:  #iter: 2, loss value: 16223.3008427702
NOTICE:  #iter: 3, loss value: 16223.5007170106
NOTICE:  #iter: 4, loss value: 16223.7005912511
NOTICE:  #iter: 5, loss value: 16223.9004654916
NOTICE:  #iter: 6, loss value: 16224.1003397321
NOTICE:  #iter: 7, loss value: 16224.3002139726
NOTICE:  #iter: 8, loss value: 16224.5000882131
NOTICE:  #iter: 9, loss value: 16224.6999624536
NOTICE:  #iter: 10, loss value: 16224.8998366941
NOTICE:  #iter: 11, loss value: 16225.0997109346
NOTICE:  #iter: 12, loss value: 16225.2995851751
NOTICE:  #iter: 13, loss value: 16225.4994594156
NOTICE:  #iter: 14, loss value: 16225.6993336561
NOTICE:  #iter: 15, loss value: 16225.8992078966
NOTICE:  #iter: 16, loss value: 16226.0990821371
NOTICE:  #iter: 17, loss value: 16226.2989563776
NOTICE:  #iter: 18, loss value: 16226.4988306181
NOTICE:  #iter: 19, loss value: 16226.6987048586
NOTICE:  #iter: 20, loss value: 16226.8985790991
 sparse_svm 
------------
 
(1 row)

Time: 5634070.592 ms (01:33:54.071)
test_bismarck=# 



logit sklearn 
Epoch  0 [305145.77190648]
--- 39.0962700843811 seconds ---
Epoch  1 [298974.97627127]
--- 77.6692099571228 seconds ---
Epoch  2 [299068.3198017]
--- 116.08256602287292 seconds ---
Epoch  3 [299133.75694716]
--- 155.05247282981873 seconds ---
Epoch  4 [298936.42298659]
--- 193.99852180480957 seconds ---
Epoch  5 [299200.3929031]
--- 232.62483096122742 seconds ---
Epoch  6 [299016.14068494]
--- 270.9761381149292 seconds ---
Epoch  7 [299080.2562]
--- 309.7645399570465 seconds ---
Epoch  8 [298770.17704546]
--- 348.1434681415558 seconds ---
Epoch  9 [298554.56533713]
--- 386.46035504341125 seconds ---
Epoch  10 [299417.27796534]
--- 425.1483941078186 seconds ---
Epoch  11 [299547.58178128]
--- 464.6201648712158 seconds ---
Epoch  12 [298354.79948822]
--- 503.2972888946533 seconds ---
Epoch  13 [299202.70480805]
--- 543.927169084549 seconds ---
Epoch  14 [299262.19768488]
--- 588.0253570079803 seconds ---
Epoch  15 [298921.41803801]
--- 631.0649271011353 seconds ---
Epoch  16 [299129.65068251]
--- 672.8658549785614 seconds ---
Epoch  17 [299285.09781856]
--- 713.5410859584808 seconds ---
Epoch  18 [299112.13437772]
--- 753.6339859962463 seconds ---
Epoch  19 [299093.04486434]
--- 794.0698571205139 seconds ---
--- 794.0699689388275 seconds ---
