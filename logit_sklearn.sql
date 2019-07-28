DROP FUNCTION IF EXISTS alloc_float8_array(double precision, double precision, integer) CASCADE;
CREATE FUNCTION alloc_float8_array(mu double precision, lr double precision, n integer)
RETURNS double precision[]
AS $$
    w = [0.0 for _ in range(n)]
    return [mu, 0.0] + w
$$ LANGUAGE plpythonu;


DROP FUNCTION IF EXISTS dense_logit_agg(double precision[], integer, double precision[]) CASCADE;
CREATE FUNCTION dense_logit_agg(x double precision[][], y integer[], linear_model double precision[])
    RETURNS double precision[]
AS $$
    import numpy as np
    from sklearn.linear_model import LogisticRegression
    from sklearn.linear_model import SGDClassifier

    mu = linear_model[0]
    lr = linear_model[1]
    w = linear_model[2:]

    # model = LogisticRegression(penalty='l1', C=mu, random_state=0, max_iter=1)
    model = SGDClassifier(loss='log', penalty='l1', classes=[-1,1], random_state=0, warm_start=True)

    model.partial_fit(x, y)
    w = model.coef_
    lr = model.intercept_[0]
    print(model.coef_)
            
    return [mu, lr] + list(w.T)
$$ LANGUAGE plpythonu;

DROP FUNCTION IF EXISTS dense_logit_loss(double precision[], integer, double precision[]) CASCADE;
CREATE FUNCTION dense_logit_loss(x double precision[], y integer, linear_model double precision[])
    RETURNS double precision
AS $$
    import numpy as np
    
    w = linear_model[2:]
    wx = np.dot(x, w)

    return np.log(1.0 + np.exp(- y * wx))

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
    offset integer;
    iteration integer := 101;

    BEGIN
    -- grad
    offset := (i-1) * length;
    FOR i IN 1..iteration LOOP
        EXECUTE 'SELECT dense_logit_agg(
                    (SELECT vec 
                     FROM ' || quote_ident(data_table)
                || 'LIMIT ' || length 
                || 'OFFSET ' || offset || '), 
                    (SELECT labeli
                     FROM ' || quote_ident(data_table)
                || 'LIMIT ' || length 
                || 'OFFSET ' || offset || '), 
                    (SELECT parms 
                     FROM linear_model 
                     WHERE mid = ' || model_id || ')) '            
            INTO weight_vector;
        -- update
        UPDATE linear_model SET parms = weight_vector WHERE mid = model_id;
        -- loss
        EXECUTE 'SELECT sum(dense_logit_loss(vec, labeli, 
                               (SELECT parms
                                FROM linear_model 
                                WHERE mid = ' || model_id || '))) '
                || 'FROM ' || quote_ident(data_table)
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
