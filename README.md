# PyBismarck

This effort is part of the CS848, Advanced Topics in Databases: DB for ML, ML for DB (Spring 2019), course project.

Our work is mainly based on Bismarck[1], which provides a unified architecture to deploy different in-RDBMS analytic algorithms to different database systems. We proposed to replicate their work using Python and extend to more advanced machine learning algorithms. To accelerate the training process, we implemented Mini-Batch Gradient Descent via the user-defined aggregate functions in PostgreSQL. 

In this project, we demonstrated the possibility of developing the unified architecture for applying machine learning algorithms to in-RDBMS analytics using Python libraries. Although it's slower than C-implemented Bismarck, it enables easier deployment, training control and model tunning.

Thank Prof. Ken Salem for his help and advice in our project.


[1] Feng, Xixuan, et al. "Towards a unified architecture for in-RDBMS analytics." Proceedings of the 2012 ACM SIGMOD International Conference on Management of Data. ACM, 2012.