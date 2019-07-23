DROP FUNCTION IF EXISTS alloc_float8_array(double precision, integer) CASCADE;
CREATE FUNCTION alloc_float8_array(mu double precision, n integer)
RETURNS double precision[]
AS $$
    w = [0.0 for _ in range(n)]
    return [mu] + w
$$ LANGUAGE plpythonu;


DROP FUNCTION IF EXISTS dense_svm_agg(double precision[], integer, double precision[]) CASCADE;
CREATE FUNCTION dense_svm_agg(x double precision[], y integer, linear_model double precision[])
    RETURNS double precision[]
AS $$
    import numpy as np

    learn_rate = linear_model[0]
    theta = linear_model[1:]
    xa = np.array(x)
    
    v = np.dot(xa, theta)
    if (y * v < 1):
        gradient = [y * xa[i] - theta[i] for i in range(len(theta))]
    else:
        gradient = [ - theta[i] for i in range(len(theta))]

    for i in range(len(theta)):
        theta[i] += learn_rate * gradient[i]
        
    return [learn_rate] + theta
$$ LANGUAGE plpythonu;

DROP FUNCTION IF EXISTS dense_svm_loss(double precision[], integer, double precision[]) CASCADE;
CREATE FUNCTION dense_svm_loss(x double precision[], y integer, linear_model double precision[])
    RETURNS double precision
AS $$
    import numpy as np
    
    learn_rate = linear_model[0]
    theta = linear_model[1:]
    xa = np.array(x)
    v = np.dot(xa, theta)
    
    return max(0, 1 - y * v)
$$ LANGUAGE plpythonu;

DROP FUNCTION IF EXISTS dense_svm_agg_iteration(text, integer) CASCADE;
CREATE FUNCTION dense_svm_agg_iteration(data_table text, model_id integer)
RETURNS double precision 
AS $$
DECLARE
    weight_vector double precision[];
    loss double precision;
    BEGIN
    -- grad
    EXECUTE 'SELECT dense_svm_agg(vec, labeli, 
                            (SELECT parms 
                             FROM linear_model 
                             WHERE mid = ' || model_id || ')) '
            || 'FROM ' || quote_ident(data_table)
        INTO weight_vector;
    -- update
    UPDATE linear_model SET parms = weight_vector WHERE mid = model_id;
    -- loss
    EXECUTE 'SELECT sum(dense_svm_loss(vec, labeli, 
                           (SELECT parms
                            FROM linear_model 
                            WHERE mid = ' || model_id || '))) '
            || 'FROM ' || quote_ident(data_table)
        INTO loss;
    RETURN loss;
END;
$$ LANGUAGE plpgsql VOLATILE;

DROP FUNCTION IF EXISTS dense_svm_train_agg(text, integer, integer) CASCADE;
CREATE FUNCTION dense_svm_train_agg(data_table text, model_id integer, iteration integer)
RETURNS VOID 
AS $$
DECLARE
    loss double precision;
    BEGIN
    FOR i IN 1..iteration LOOP
        SELECT dense_svm_agg_iteration(data_table, model_id) INTO loss;
        RAISE NOTICE '#iter: %, loss value: %', i, loss;
    END LOOP;
END;
$$ LANGUAGE plpgsql VOLATILE;


DROP FUNCTION IF EXISTS dense_svm(text, integer, integer, integer, boolean) CASCADE;
CREATE FUNCTION dense_svm(
    data_table text,
    model_id integer,
    ndims integer,
    iteration integer /* default 20 */,
    mu double precision /* default 1e-2 */,
    is_shuffle boolean /* default 'true' */)
RETURNS VOID AS $$
DECLARE
    ntuples integer;
    tmp_table text;
    initw double precision[] := '{0}';
BEGIN
    -- query for ntuples and initialize the model table 
    EXECUTE 'SELECT count(*) FROM ' || data_table
        INTO ntuples;   
    RAISE NOTICE '#tuples: %', ntuples; 
    SELECT alloc_float8_array(mu, ndims) INTO initw;
    DELETE FROM linear_model WHERE mid = model_id;
    INSERT INTO linear_model VALUES (model_id, initw); 
    -- execute iterations
    IF is_shuffle THEN
        tmp_table := '__bismarck_shuffled_' || data_table || '_' || model_id;
        EXECUTE 'DROP TABLE IF EXISTS ' || tmp_table || ' CASCADE';
        EXECUTE 'CREATE TABLE ' || tmp_table || ' AS 
            SELECT * FROM ' || data_table || ' ORDER BY random()';
        RAISE NOTICE 'A shuffled table % is created for training', tmp_table;
    ELSE
        tmp_table := data_table;
    END IF;

    PERFORM dense_svm_train_agg(tmp_table, model_id, iteration);
END;
$$ LANGUAGE plpgsql VOLATILE;


DROP FUNCTION IF EXISTS dense_svm(text, integer, integer) CASCADE;
CREATE FUNCTION dense_svm(
    data_table text,
    model_id integer,
    ndims integer)
RETURNS VOID AS $$
    SELECT dense_svm($1, $2, $3, 20, 5e-3, 't');
$$ LANGUAGE sql VOLATILE;