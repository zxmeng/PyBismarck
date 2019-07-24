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
