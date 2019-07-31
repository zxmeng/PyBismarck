test_bismarck=# SELECT dense_logit('forest', 22, 54);
NOTICE:  #tuples: 581012
NOTICE:  A shuffled table __bismarck_shuffled_forest_22 is created for training
NOTICE:  #iter: 1, loss value: 0.692692003799292
NOTICE:  #iter: 2, loss value: 0.693157697576192
NOTICE:  #iter: 3, loss value: 0.69246481879447
 dense_logit 
-------------
 
(1 row)

Time: 576141.480 ms (09:36.141)

batch size 100000

NOTICE:  #tuples: 581012
NOTICE:  A shuffled table __bismarck_shuffled_forest_22 is created for training
NOTICE:  #iter: 1, loss value: 0.692342901854197
NOTICE:  #iter: 2, loss value: 0.691539485980704
NOTICE:  #iter: 3, loss value: 0.690736932359448
 dense_logit 
-------------
 
(1 row)

Time: 237543.025 ms (03:57.543)

batch size 500000


test_bismarck=# SELECT dense_logit('forest', 22, 54);
NOTICE:  #tuples: 581012
NOTICE:  A shuffled table __bismarck_shuffled_forest_22 is created for training
NOTICE:  #iter: 1, loss value: 0.693722781739399
NOTICE:  #iter: 2, loss value: 0.692660034783302
NOTICE:  #iter: 3, loss value: 0.693898531457358
 dense_logit 
-------------
 
(1 row)

Time: 1296049.361 ms (21:36.049)

batch size 50000

test_bismarck=# SELECT dense_svm('forest', 5, 54);
NOTICE:  #tuples: 581012
NOTICE:  table "__bismarck_shuffled_forest_5" does not exist, skipping
NOTICE:  A shuffled table __bismarck_shuffled_forest_5 is created for training
NOTICE:  #iter: 1, loss value: 0.999514679861104
NOTICE:  #iter: 2, loss value: 0.999025672444647
NOTICE:  #iter: 3, loss value: 1.00047609949802
 dense_svm 
-----------
 
(1 row)

Time: 570059.019 ms (09:30.059)


test_bismarck=# SELECT dense_svm('forest', 5, 54);
NOTICE:  #tuples: 581012
NOTICE:  A shuffled table __bismarck_shuffled_forest_5 is created for training
NOTICE:  #iter: 1, loss value: 1.00037289997239
NOTICE:  #iter: 2, loss value: 0.998710123719649
NOTICE:  #iter: 3, loss value: 0.999712125611361
 dense_svm 
-----------
 
(1 row)

Time: 565201.087 ms (09:25.201)