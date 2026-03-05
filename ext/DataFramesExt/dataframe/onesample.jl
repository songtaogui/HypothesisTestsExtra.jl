#FILEPATH: ext/DataFramesExt/dataframe/onesample.jl

"""
    HypothesisTests.OneSampleTTest(df::DataFrame, data_col::Symbol, mu::Real=0)

One-sample Student t-test on `data_col` against mean `mu`.
Type requirements: `data_col` (Numeric).
Missing/invalid values are removed before testing.
"""
function HypothesisTests.OneSampleTTest(df::DataFrame, data_col::Symbol, mu::Real = 0)
    _validate_columns(df, data_col => :numeric)
    data = _get_clean_data(df[:, data_col])
    return HypothesisTests.OneSampleTTest(data, mu)
end

"""
    HypothesisTests.OneSampleZTest(df::DataFrame, data_col::Symbol, mu::Real=0)

One-sample z-test on `data_col` against mean `mu`.
Type requirements: `data_col` (Numeric).
Missing/invalid values are removed before testing.
"""
function HypothesisTests.OneSampleZTest(df::DataFrame, data_col::Symbol, mu::Real = 0)
    _validate_columns(df, data_col => :numeric)
    data = _get_clean_data(df[:, data_col])
    return HypothesisTests.OneSampleZTest(data, mu)
end

"""
    HypothesisTests.SignTest(df::DataFrame, data_col::Symbol, median::Real=0)

One-sample sign test on `data_col` against `median`.
Type requirements: `data_col` (Numeric).
Missing/invalid values are removed before testing.
"""
function HypothesisTests.SignTest(df::DataFrame, data_col::Symbol, median::Real = 0)
    _validate_columns(df, data_col => :numeric)
    data = _get_clean_data(df[:, data_col])
    return HypothesisTests.SignTest(data, median)
end

"""
    HypothesisTests.SignedRankTest(df::DataFrame, data_col::Symbol)

One-sample Wilcoxon signed-rank test on `data_col`.
Type requirements: `data_col` (Numeric).
Missing/invalid values are removed before testing.
"""
function HypothesisTests.SignedRankTest(df::DataFrame, data_col::Symbol)
    _validate_columns(df, data_col => :numeric)
    data = _get_clean_data(df[:, data_col])
    return HypothesisTests.SignedRankTest(data)
end

"""
    HypothesisTests.BinomialTest(df::DataFrame, data_col::Symbol, p::Real=0.5)

Exact binomial test for a binary column against success probability `p`.
Type requirements: `data_col` (Binary, exactly 2 levels).
Non-`Bool` binary values are coerced to boolean internally.
"""
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
