DROP FUNCTION IF EXISTS alloc_float8_array(double precision, double precision, integer) CASCADE;
CREATE FUNCTION alloc_float8_array(mu double precision, lr double precision, n integer)
RETURNS double precision[]
AS $$
    w = [0.0 for _ in range(n)]
    return [mu, lr] + w
$$ LANGUAGE plpythonu;


DROP FUNCTION IF EXISTS sparse_logit_agg(integer[], double precision[], integer, double precision[]) CASCADE;
CREATE FUNCTION sparse_logit_agg(k integer[], v double precision[], y integer, linear_model double precision[])
    RETURNS double precision[]
AS $$
    import numpy as np

    mu = linear_model[0]
    lr = linear_model[1]
    w = linear_model[2:]

    wx = 0.0
    for i in range(len(k)):
        wx += v[i] * w[k[i]]

    sig = 1.0 / (1.0 + np.exp(- wx * y))
    c = lr * y * sig
    u = mu * lr

    for i in range(len(k)):
        w[k[i]] += v[i] * c
        
        if w[k[i]] > u:
            w[k[i]] -= u
        elif w[k[i]] < -u:
            w[k[i]] += u
        else:
            w[k[i]] = 0.0
            
    return [mu, lr] + w
$$ LANGUAGE plpythonu;

DROP FUNCTION IF EXISTS sparse_logit_loss(integer[], double precision[], integer, double precision[]) CASCADE;
CREATE FUNCTION sparse_logit_loss(k integer[], v double precision[], y integer, linear_model double precision[])
    RETURNS double precision
AS $$
    import numpy as np
    
    w = linear_model[2:]
    wx = 0.0
    for i in range(len(k)):
        wx += v[i] * w[k[i]]

    return np.log(1.0 + np.exp(- y * wx))

$$ LANGUAGE plpythonu;

DROP FUNCTION IF EXISTS sparse_logit_agg_iteration(text, integer) CASCADE;
CREATE FUNCTION sparse_logit_agg_iteration(data_table text, model_id integer)
RETURNS double precision 
AS $$
DECLARE
    weight_vector double precision[];
    loss double precision;
    BEGIN
    -- grad
    EXECUTE 'SELECT sparse_logit_agg(k, v, label, 
                            (SELECT parms 
                             FROM linear_model 
                             WHERE mid = ' || model_id || ')) '
            || 'FROM ' || quote_ident(data_table)
        INTO weight_vector;
    -- update
    UPDATE linear_model SET parms = weight_vector WHERE mid = model_id;
    -- loss
    EXECUTE 'SELECT sum(sparse_logit_loss(k, v, label, 
                           (SELECT parms
                            FROM linear_model 
                            WHERE mid = ' || model_id || '))) '
            || 'FROM ' || quote_ident(data_table)
        INTO loss;
    RETURN loss;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE FUNCTION sparse_logit_train_agg(data_table text, model_id integer, iteration integer)
RETURNS VOID 
AS $$
DECLARE
    loss double precision;
    BEGIN
    FOR i IN 1..iteration LOOP
        SELECT sparse_logit_agg_iteration(data_table, model_id) INTO loss;
        RAISE NOTICE '#iter: %, loss value: %', i, loss;
    END LOOP;
END;
$$ LANGUAGE plpgsql VOLATILE;

DROP FUNCTION IF EXISTS sparse_logit(text, integer, integer, integer, double precision, double precision, boolean) CASCADE;
CREATE FUNCTION sparse_logit(
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

    PERFORM sparse_logit_train_agg(tmp_table, model_id, iteration);
END;
$$ LANGUAGE plpgsql VOLATILE;

DROP FUNCTION IF EXISTS sparse_logit(text, integer, integer) CASCADE;
CREATE FUNCTION sparse_logit(
    data_table text,
    model_id integer,
    ndims integer)
RETURNS VOID AS $$
    SELECT sparse_logit($1, $2, $3, 20, 1e-2, 5e-5, 't');
$$ LANGUAGE sql VOLATILE;