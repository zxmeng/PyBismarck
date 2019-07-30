DROP FUNCTION IF EXISTS alloc_float8_array(double precision, double precision, integer) CASCADE;
CREATE FUNCTION alloc_float8_array(mu double precision, lr double precision, n integer)
RETURNS double precision[]
AS $$
    w = [0.0 for _ in range(n)]
    return [mu, 0.0] + w
$$ LANGUAGE plpythonu;

DROP FUNCTION IF EXISTS dense_logit_agg(double precision[][], integer[], double precision[]) CASCADE;
CREATE FUNCTION dense_logit_agg(datax double precision[][], datay integer[], linear_model double precision[])
    RETURNS double precision[]
AS $$
    import numpy as np
    import pandas as pd

    mu = linear_model[0]
    lr = linear_model[1]
    w = linear_model[2:]
    wa = np.array(w)

    x = np.array(datax)
    y = np.array(datay)

    z = np.dot(x, w) 
    h = 1 / (1 + np.exp(-z))

    gradient = np.dot(x.T, (h - y)) / len(y)
    wa -= lr * gradient

    return y

$$ LANGUAGE plpythonu;

DROP FUNCTION IF EXISTS dense_logit_loss(double precision[][], integer[], double precision[]) CASCADE;
CREATE FUNCTION dense_logit_loss(datax double precision[][], datay integer[], linear_model double precision[])
    RETURNS double precision
AS $$
    import numpy as np
    import pandas as pd

    x = np.array(datax)
    y = np.array(datay)
    
    w = linear_model[2:]
    z = np.dot(x, w) 
    h = 1 / (1 + np.exp(-z))

    return (-y * np.log(h) - (1 - y) * np.log(1 - h)).mean()

$$ LANGUAGE plpythonu;

DROP FUNCTION IF EXISTS dense_logit_agg_iteration(text, integer) CASCADE;
CREATE FUNCTION dense_logit_agg_iteration(data_table text, model_id integer)
RETURNS double precision 
AS $$
DECLARE
    weight_vector double precision[];
    loss double precision := 0.0;
    loss_epo double precision;
    length integer := 5000;
    shift integer := 0;
    iteration integer := 101;

    BEGIN
    -- grad
    FOR i IN 1..iteration LOOP
        shift := (i-1) * length;
        -- EXECUTE 'SELECT dense_logit_agg(
        --             get_dataset(' || quote_ident(data_table), length, shift || '), parms)              
        --          FROM linear_model
        --          WHERE mid = ' || model_id  
        --     INTO weight_vector;

        EXECUTE 'SELECT labeli, dense_logit_agg(vec, labeli)'


        EXECUTE 'SELECT *
                 FROM dense_logit_agg(
                    (SELECT vec, labeli
                     FROM ' || quote_ident(data_table)
                 || ' LIMIT ' || length 
                 || ' OFFSET ' || shift 
                 || ' GROUP BY labeli),
                    (SELECT parms              
                     FROM linear_model
                     WHERE mid = ' || model_id || '))' 
            INTO weight_vector;
        -- EXECUTE 'SELECT *
        --          FROM dense_logit_agg(
        --             get_dataset(' || quote_ident(data_table), length, shift || '),
        --             (SELECT parms              
        --              FROM linear_model
        --              WHERE mid = ' || model_id || '))' 
        --     INTO weight_vector;
        -- RAISE NOTICE 'weights: %', weight_vector;
        -- update
        UPDATE linear_model SET parms = weight_vector WHERE mid = model_id;
        -- loss
        -- EXECUTE 'SELECT dense_logit_loss(
        --             (SELECT vec, labeli
        --              FROM ' || quote_ident(data_table)
        --          || ' LIMIT ' || length 
        --          || ' OFFSET ' || shift 
        --          || '), parms)              
        --          FROM linear_model
        --          WHERE mid = ' || model_id  
        --     INTO loss_epo;
        -- EXECUTE 'SELECT *
        --          FROM dense_logit_loss(
        --             get_dataset(' || quote_ident(data_table), length, shift || '),
        --             (SELECT parms              
        --              FROM linear_model
        --              WHERE mid = ' || model_id || '))' 
        --     INTO loss_epo;
        EXECUTE 'SELECT *
                 FROM dense_logit_loss(
                    (SELECT vec
                     FROM ' || quote_ident(data_table)
                 || ' LIMIT ' || length 
                 || ' OFFSET ' || shift 
                 || '), 
                    (SELECT labeli
                     FROM ' || quote_ident(data_table)
                 || ' LIMIT ' || length 
                 || ' OFFSET ' || shift 
                 || '),
                    (SELECT parms              
                    FROM linear_model
                    WHERE mid = ' || model_id || '))' 
            INTO loss_epo;
        loss := loss_epo + loss;
    END LOOP;
    RETURN loss;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE FUNCTION dense_logit_train_agg(data_table text, model_id integer, iteration integer)
RETURNS VOID 
AS $$
DECLARE
    loss double precision;
    BEGIN
    FOR i IN 1..iteration LOOP
        SELECT dense_logit_agg_iteration(data_table, model_id) INTO loss;
        RAISE NOTICE '#iter: %, loss value: %', i, loss;
    END LOOP;
END;
$$ LANGUAGE plpgsql VOLATILE;

DROP FUNCTION IF EXISTS dense_logit(text, integer, integer, integer, double precision, double precision, boolean) CASCADE;
CREATE FUNCTION dense_logit(
    data_table text,
    model_id integer,
    ndims integer,
    iteration integer /* default 20 */,
    mu double precision /* default 1e-2 */,
    lr double precision /* default 5e-5 */,
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
    SELECT alloc_float8_array(mu, lr, ndims) INTO initw;
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

    PERFORM dense_logit_train_agg(tmp_table, model_id, iteration);
END;
$$ LANGUAGE plpgsql VOLATILE;

DROP FUNCTION IF EXISTS dense_logit(text, integer, integer) CASCADE;
CREATE FUNCTION dense_logit(
    data_table text,
    model_id integer,
    ndims integer)
RETURNS VOID AS $$
    SELECT dense_logit($1, $2, $3, 20, 1e-2, 5e-5, 'f');
$$ LANGUAGE sql VOLATILE;
