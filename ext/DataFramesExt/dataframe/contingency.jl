function PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol; pairs=nothing, kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, r_labels, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    idx_pairs = _normalize_pairs(pairs, r_labels)
    return PostHocContingencyRow(tbl; row_labels=r_labels, pairs=idx_pairs, kwargs...)
end

function PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    return PostHocContingencyCell(tbl; kwargs...)
end

function PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; pairs=nothing, kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, r_labels, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    idx_pairs = _normalize_pairs(pairs, r_labels)
    return PostHocContingencyRow(tbl; row_labels=r_labels, pairs=idx_pairs, kwargs...)
end

function PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    return PostHocContingencyCell(tbl; kwargs...)
end

function HypothesisTests.ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    _assert_requirement(all(size(tbl) .>= 2), "ChisqTest requires at least 2x2 table.")
    return HypothesisTests.ChisqTest(tbl)
end

function HypothesisTests.ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    return HypothesisTests.ChisqTest(tbl)
end

function HypothesisTests.FisherExactTest(tbl::AbstractMatrix{<:Integer})
    r, c = size(tbl)
    if r != 2 || c != 2
        error("FisherExactTest currently only supports 2x2 tables. Found $(r)x$(c).")
    end
    return HypothesisTests.FisherExactTest(vec(tbl')...)
end

function HypothesisTests.FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    _assert_requirement(size(tbl) == (2, 2), "FisherExactTest requires a 2x2 table.")
    return HypothesisTests.FisherExactTest(vec(tbl')...)
end

function HypothesisTests.FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    _assert_requirement(size(tbl) == (2, 2), "FisherExactTest requires a 2x2 table.")
    return HypothesisTests.FisherExactTest(vec(tbl')...)
end

function FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    return FisherExactTestRxC(tbl)
end

function FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    return FisherExactTestRxC(tbl)
end

function HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    _assert_requirement(all(size(tbl) .>= 2), "PowerDivergenceTest requires at least 2x2 table.")
    return HypothesisTests.PowerDivergenceTest(tbl; kwargs...)
end

function HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    _assert_requirement(all(size(tbl) .>= 2), "PowerDivergenceTest requires at least 2x2 table.")
    return HypothesisTests.PowerDivergenceTest(tbl; kwargs...)
end
