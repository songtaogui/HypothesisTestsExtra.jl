function HypothesisTests.OneSampleTTest(df::DataFrame, data_col::Symbol, mu::Real = 0)
    _validate_columns(df, data_col => :numeric)
    data = _get_clean_data(df[:, data_col])
    return HypothesisTests.OneSampleTTest(data, mu)
end

function HypothesisTests.OneSampleZTest(df::DataFrame, data_col::Symbol, mu::Real = 0)
    _validate_columns(df, data_col => :numeric)
    data = _get_clean_data(df[:, data_col])
    return HypothesisTests.OneSampleZTest(data, mu)
end

function HypothesisTests.SignTest(df::DataFrame, data_col::Symbol, median::Real = 0)
    _validate_columns(df, data_col => :numeric)
    data = _get_clean_data(df[:, data_col])
    return HypothesisTests.SignTest(data, median)
end

function HypothesisTests.SignedRankTest(df::DataFrame, data_col::Symbol)
    _validate_columns(df, data_col => :numeric)
    data = _get_clean_data(df[:, data_col])
    return HypothesisTests.SignedRankTest(data)
end

function HypothesisTests.BinomialTest(df::DataFrame, data_col::Symbol, p::Real = 0.5)
    _validate_columns(df, data_col => :binary)
    data = _get_clean_data(df[:, data_col])

    booldata =
        if eltype(data) <: Bool
            data
        else
            try
                Bool.(data)
            catch
                data .== unique(data)[1]
            end
        end

    return HypothesisTests.BinomialTest(booldata, p)
end
