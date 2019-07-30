DROP FUNCTION IF EXISTS alloc_float8_array(double precision, double precision, integer) CASCADE;
CREATE FUNCTION alloc_float8_array(mu double precision, lr double precision, n integer)
RETURNS double precision[]
AS $$
    w = [0.0 for _ in range(n)]
    return [mu, lr] + w
$$ LANGUAGE plpythonu;


DROP FUNCTION IF EXISTS dense_logit_transit(double precision[][], double precision[], integer, double precision[]) CASCADE;
CREATE FUNCTION dense_logit_transit(state double precision[][], x double precision[], y integer, linear_model double precision[])
    RETURNS double precision[]
AS $$
    if not state:
        state = [linear_model] + [x + [y]]
    else:
        state += [x + [y]]
    return state
   

$$ LANGUAGE plpythonu;

DROP FUNCTION IF EXISTS dense_logit_final(double precision[][]) CASCADE;
CREATE FUNCTION dense_logit_final(state double precision[][])
    RETURNS double precision[]
AS $$
    from sklearn.linear_model import LogisticRegression

    global state
    linear_model = state[0]
    mu = linear_model[0]
    lr = linear_model[1]
    w = linear_model[2:]
    wa = np.array(w)

    state = np.array(state[1:])
    x = state[:, :-1]
    y = s[:, -1]

    clf = LogisticRegression(random_state=0, penalty='l1', max_iter=10, warm_start=True)
    clf.coef_[0] = wa
    clf.fit(x, y)
    
    return [mu, lr] + list(clf.coef_[0])
    
$$ LANGUAGE plpythonu;


CREATE AGGREGATE dense_logit_agg(double precision[], integer, double precision[]) (
    STYPE = double precision[][],
    SFUNC = dense_logit_transit,
    FINALFUNC = dense_logit_final
    );


DROP FUNCTION IF EXISTS dense_logit_loss_transit(double precision[][], double precision[], integer, double precision[]) CASCADE;
CREATE FUNCTION dense_logit_loss_transit(state double precision[][], x double precision[], y integer, linear_model double precision[])
    RETURNS double precision[]
AS $$
    if not state:
        state = [linear_model] + [x + [y]]
    else:
        state += [x + [y]]
    return state
   

$$ LANGUAGE plpythonu;

DROP FUNCTION IF EXISTS dense_logit_loss_final(double precision[][]) CASCADE;
CREATE FUNCTION dense_logit_loss_final(state double precision[][])
    RETURNS double precision
AS $$
    from sklearn.linear_model import LogisticRegression

    global state
    linear_model = state[0]
    mu = linear_model[0]
    lr = linear_model[1]
    w = linear_model[2:]
    wa = np.array(w)

    state = np.array(state[1:])
    x = state[:, :-1]
    y = s[:, -1]

    clf = LogisticRegression(random_state=0, penalty='l1', max_iter=10, warm_start=True)
    clf.coef_[0] = wa

    return clf.score(x, y)
    
$$ LANGUAGE plpythonu;


CREATE AGGREGATE dense_logit_loss(double precision[], integer, double precision[]) (
    STYPE = double precision[][],
    SFUNC = dense_logit_loss_transit,
    FINALFUNC = dense_logit_loss_final
    );


DROP FUNCTION IF EXISTS dense_logit_agg_iteration(text, integer) CASCADE;
CREATE FUNCTION dense_logit_agg_iteration(data_table text, model_id integer)
RETURNS double precision 
AS $$
DECLARE
    weight_vector double precision[];
    loss double precision := 0.0;
    length integer := 50000;
    shift integer := 0;
    iteration integer := 11;
    BEGIN
    FOR i IN 1..iteration LOOP
        shift := (i-1) * length;
        -- grad
        EXECUTE 'SELECT dense_logit_agg(vec, labeli, 
                                (SELECT parms 
                                 FROM linear_model 
                                 WHERE mid = ' || model_id || ')) '
                || 'FROM ' || quote_ident(data_table)
                || ' LIMIT ' || length 
                || ' OFFSET ' || shift 
            INTO weight_vector;
        -- update
        UPDATE linear_model SET parms = weight_vector WHERE mid = model_id;
    END LOOP;
    -- loss
    shift := iteration * length;
    EXECUTE 'SELECT dense_logit_loss(vec, labeli, 
                           (SELECT parms
                            FROM linear_model 
                            WHERE mid = ' || model_id || ')) '
            || 'FROM ' || quote_ident(data_table)
            || ' LIMIT ' || length 
            || ' OFFSET ' || shift 
        INTO loss;
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
    SELECT dense_logit($1, $2, $3, 3, 1e-2, 5e-5, 't');
$$ LANGUAGE sql VOLATILE;