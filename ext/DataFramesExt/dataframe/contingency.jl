#FILEPATH: ext/DataFramesExt/dataframe/contingency.jl

"""
    PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol; pairs=nothing, kwargs...)

Post-hoc row-wise comparisons for a contingency table built from raw records.
Type requirements: `row_col` (Categorical), `col_col` (Categorical).
`pairs` may limit tested row-pairs.
"""
function PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol; pairs=nothing, kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, r_labels, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    idx_pairs = _normalize_pairs(pairs, r_labels)
    return PostHocContingencyRow(tbl; row_labels=r_labels, pairs=idx_pairs, kwargs...)
end

"""
    PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Post-hoc cell-wise tests for a contingency table built from raw records.
Type requirements: `row_col` (Categorical), `col_col` (Categorical).
"""
function PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    return PostHocContingencyCell(tbl; kwargs...)
end

"""
    PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; pairs=nothing, kwargs...)

Post-hoc row-wise comparisons for a contingency table with frequency weights.
Type requirements: `row_col` (Categorical), `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
"""
function PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; pairs=nothing, kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, r_labels, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    idx_pairs = _normalize_pairs(pairs, r_labels)
    return PostHocContingencyRow(tbl; row_labels=r_labels, pairs=idx_pairs, kwargs...)
end

"""
    PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Post-hoc cell-wise tests for a contingency table with frequency weights.
Type requirements: `row_col` (Categorical), `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
"""
function PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    return PostHocContingencyCell(tbl; kwargs...)
end

"""
    HypothesisTests.ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol)

Pearson chi-square test of independence from raw records.
Type requirements: `row_col` (Categorical), `col_col` (Categorical).
Requires at least a 2x2 contingency table.
"""
function HypothesisTests.ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    _assert_requirement(all(size(tbl) .>= 2), "ChisqTest requires at least 2x2 table.")
    return HypothesisTests.ChisqTest(tbl)
end

"""
    HypothesisTests.ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Pearson chi-square test of independence from weighted frequencies.
Type requirements: `row_col` (Categorical), `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
"""
function HypothesisTests.ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    return HypothesisTests.ChisqTest(tbl)
end

"""
    HypothesisTests.FisherExactTest(tbl::AbstractMatrix{<:Integer})

Fisher exact test for a 2x2 integer contingency table.
Errors if the table is not 2x2.
"""
function HypothesisTests.FisherExactTest(tbl::AbstractMatrix{<:Integer})
    r, c = size(tbl)
    if r != 2 || c != 2
        error("FisherExactTest currently only supports 2x2 tables. Found $(r)x$(c).")
    end
    return HypothesisTests.FisherExactTest(vec(tbl')...)
end

"""
    HypothesisTests.FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol)

Fisher exact test from raw records.
Type requirements: `row_col` (Categorical), `col_col` (Categorical).
Requires a 2x2 contingency table.
"""
function HypothesisTests.FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    _assert_requirement(size(tbl) == (2, 2), "FisherExactTest requires a 2x2 table.")
    return HypothesisTests.FisherExactTest(vec(tbl')...)
end

"""
    HypothesisTests.FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Fisher exact test from weighted frequencies.
Type requirements: `row_col` (Categorical), `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
Requires a 2x2 contingency table.
"""
function HypothesisTests.FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    _assert_requirement(size(tbl) == (2, 2), "FisherExactTest requires a 2x2 table.")
    return HypothesisTests.FisherExactTest(vec(tbl')...)
end

"""
    FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol)

Fisher exact test for general `R x C` contingency tables from raw records.
Type requirements: `row_col` (Categorical), `col_col` (Categorical).
"""
function FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    return FisherExactTestRxC(tbl)
end

"""
    FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Fisher exact test for general `R x C` contingency tables with weighted frequencies.
Type requirements: `row_col` (Categorical), `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
"""
function FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    return FisherExactTestRxC(tbl)
end

"""
    HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Power-divergence family test of independence from raw records.
Type requirements: `row_col` (Categorical), `col_col` (Categorical).
Requires at least a 2x2 contingency table.
"""
function HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, nothing)
    _assert_requirement(all(size(tbl) .>= 2), "PowerDivergenceTest requires at least 2x2 table.")
    return HypothesisTests.PowerDivergenceTest(tbl; kwargs...)
end

"""
    HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Power-divergence family test of independence from weighted frequencies.
Type requirements: `row_col` (Categorical), `col_col` (Categorical), `freq_col` (Numeric integer-like counts).
Requires at least a 2x2 contingency table.
"""
function HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl, _, _ = _pivot_freq_table(df, row_col, col_col, freq_col)
    _assert_requirement(all(size(tbl) .>= 2), "PowerDivergenceTest requires at least 2x2 table.")
    return HypothesisTests.PowerDivergenceTest(tbl; kwargs...)
end
