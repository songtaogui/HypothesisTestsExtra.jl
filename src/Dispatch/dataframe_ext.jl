# src/Dispatch/dataframe_ext.jl

# ==============================================================================
# Extension: Post-hoc Tests (DataFrame)
# ==============================================================================

"""
    PostHocNonPar(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
Non-parametric post-hoc (e.g., Dunn). 
Type requirements: `group_col` (Categorical), `data_col` (Numeric or Ordered).
"""
function PostHocNonPar(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
    _validate_columns(df, group_col => :categorical)
    # data_col can be numeric or ordered
    _assert_requirement(_is_numeric(df[!, data_col]) || _is_ordered(df[!, data_col]), "Column :$data_col must be numeric or ordered.")
    
    force_num = _is_ordered(df[!, data_col])
    groups, labels = _extract_groups_with_labels(df, group_col, data_col; force_numeric_data=force_num)
    return PostHocNonPar(groups; row_labels=labels, kwargs...)
end


"""
    PostHocPar(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
Parametric post-hoc (e.g., Tukey). 
Type requirements: `group_col` (Categorical), `data_col` (Numeric).
"""
function PostHocPar(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, labels = _extract_groups_with_labels(df, group_col, data_col)
    return PostHocPar(groups; row_labels=labels, kwargs...)
end

# --- Contingency Table Post-Hoc: Raw Data ---

"""
    PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Perform row-wise post-hoc comparisons (e.g., Chi-Sq or Fisher) on raw categorical data.
"""
function PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl = _pivot_freq_table(df, row_col, col_col, nothing)
    return PostHocContingencyRow(tbl; kwargs...)
end

"""
    PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Perform cell-level post-hoc analysis (e.g., ASR) on raw categorical data.
"""
function PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl = _pivot_freq_table(df, row_col, col_col, nothing)
    return PostHocContingencyCell(tbl; kwargs...)
end

# --- Contingency Table Post-Hoc: Frequency Data ---

"""
    PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Perform row-wise post-hoc comparisons on aggregated frequency data (Long format).
"""
function PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    return PostHocContingencyRow(tbl; kwargs...)
end

"""
    PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Perform cell-level post-hoc analysis on aggregated frequency data (Long format).
"""
function PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    return PostHocContingencyCell(tbl; kwargs...)
end

# ==============================================================================
# Extension: Standard Categorical Tests (DataFrame)
# ==============================================================================

"""
    ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol)

Compute Pearson's Chi-square test from a raw DataFrame.
"""
function HypothesisTests.ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl = _pivot_freq_table(df, row_col, col_col, nothing)
    _assert_requirement(all(size(tbl) .>= 2), "ChisqTest requires at least 2x2 table.")
    return HypothesisTests.ChisqTest(tbl)
end

function HypothesisTests.ChisqTest(tbl::NamedMatrix) HypothesisTests.ChisqTest(tbl.array) end

"""
    ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Compute Pearson's Chi-square test from aggregated frequency data.
"""
function HypothesisTests.ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    return ChisqTest(tbl)
end

"""
    FisherExactTest(tbl::AbstractMatrix{<:Integer})

Compute Fisher's Exact Test from a ct (2x2 only).
"""
function HypothesisTests.FisherExactTest(tbl::AbstractMatrix{<:Integer})
    r, c = size(tbl)
    if r != 2 || c != 2
        error("FisherExactTest currently only supports 2x2 tables. Found $(r)x$(c).")
    end
    return FisherExactTest(vec(tbl')...)
end

"""
    FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol)

Compute Fisher's Exact Test from a raw DataFrame (2x2 only).
"""
function HypothesisTests.FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl = _pivot_freq_table(df, row_col, col_col, nothing)
    _assert_requirement(size(tbl) == (2, 2), "FisherExactTest requires a 2x2 table.")
    return FisherExactTest(vec(tbl')...)
end

"""
    FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Compute Fisher's Exact Test from aggregated frequency data (2x2 only).
"""
function HypothesisTests.FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    _assert_requirement(size(tbl) == (2, 2), "FisherExactTest requires a 2x2 table.")
    return FisherExactTest(vec(tbl')...)
end

"""
    FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol)

Compute Fisher's Exact Test for general RxC tables from a raw DataFrame.
"""
function FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl = _pivot_freq_table(df, row_col, col_col, nothing)
    return FisherExactTestRxC(tbl)
end

"""
    FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Compute Fisher's Exact Test (RxC) from aggregated frequency data.
"""
function FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    return FisherExactTestRxC(tbl)
end

"""
    PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Compute Power Divergence Test from a raw DataFrame.
"""
function HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical)
    tbl = _pivot_freq_table(df, row_col, col_col, nothing)
    _assert_requirement(
        size(tbl) == (2, 2), 
        "PowerDivergenceTest requires a 2x2 table.")
    return PowerDivergenceTest(tbl; kwargs...)
end

"""
    PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Compute Power Divergence Test from aggregated frequency data.
"""
function HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :categorical, col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    _assert_requirement(size(tbl) == (2, 2), "FisherExactTest requires a 2x2 table.")
    return PowerDivergenceTest(tbl; kwargs...)
end

# ==============================================================================
# Extension: K-Sample & Variance Tests (DataFrame)
# ==============================================================================

"""
    OneWayANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform One-Way ANOVA on a DataFrame.
"""
function HypothesisTests.OneWayANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return OneWayANOVATest(groups...)
end

"""
    WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Welch's ANOVA on a DataFrame.
"""
function WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return WelchANOVATest(groups...)
end

"""
    KruskalWallisTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Kruskal-Wallis Rank Sum Test on a DataFrame.
"""
function HypothesisTests.KruskalWallisTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical)
    _assert_requirement(_is_numeric(df[!, data_col]) || _is_ordered(df[!, data_col]), "KruskalWallis requires numeric or ordered DV.")
    
    force_num = _is_ordered(df[!, data_col])
    groups, _ = _extract_groups_with_labels(df, group_col, data_col; force_numeric_data=force_num)
    return KruskalWallisTest(groups...)
end

"""
    LeveneTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Levene's Test on a DataFrame.
"""
function HypothesisTests.LeveneTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return LeveneTest(groups...)
end

"""
    BrownForsytheTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Brown-Forsythe Test on a DataFrame.
"""
function HypothesisTests.BrownForsytheTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return BrownForsytheTest(groups...)
end

"""
    FlignerKilleenTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Fligner-Killeen Test on a DataFrame.
"""
function HypothesisTests.FlignerKilleenTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :categorical, data_col => :numeric)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return FlignerKilleenTest(groups...)
end

# ==============================================================================
# Extension: 2-Sample Tests (DataFrame)
# ==============================================================================

"""
    EqualVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
Perform Student's T-Test. Validation of binary groups is handled during extraction.
"""
function HypothesisTests.EqualVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return EqualVarianceTTest(x, y)
end

"""
    UnequalVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Welch's T-Test (unequal variance) on a DataFrame (exactly 2 groups).
"""
function HypothesisTests.UnequalVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return UnequalVarianceTTest(x, y)
end

"""
    VarianceFTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform F-Test for variances on a DataFrame (exactly 2 groups).
"""
function HypothesisTests.VarianceFTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return VarianceFTest(x, y)
end

"""
    MannWhitneyUTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
Perform Mann-Whitney U Test. Automatically handles categorical data codes.
"""
function HypothesisTests.MannWhitneyUTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary)
    _assert_requirement(_is_numeric(df[!, data_col]) || _is_ordered(df[!, data_col]), "MannWhitneyU requires numeric or ordered DV.")
    is_cat = _is_categorical(df[!, data_col])
    x, y = _extract_two_groups(df, group_col, data_col; force_numeric_data=is_cat)
    return MannWhitneyUTest(x, y)
end

"""
    ApproximateTwoSampleKSTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Approximate Two-Sample KS Test on a DataFrame (exactly 2 groups).
"""
function HypothesisTests.ApproximateTwoSampleKSTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    _validate_columns(df, group_col => :binary, data_col => :numeric)
    x, y = _extract_two_groups(df, group_col, data_col)
    return ApproximateTwoSampleKSTest(x, y)
end

"""
    JonckheereTerpstraTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Jonckheere-Terpstra test.
- `group_col` (IV): Must be Ordered Categorical.
- `data_col` (DV): Must be Numeric or Ordered Categorical.
"""
function JonckheereTerpstraTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    # 1. Validate Types
    _validate_columns(df, group_col => :ordered)
    _assert_requirement(
        _is_numeric(df[!, data_col]) || _is_ordered(df[!, data_col]), 
        "JonckheereTerpstra requires numeric or ordered DV.")
    
    # 2. Extract and Dispatch
    force_num = _is_ordered(df[!, data_col])
    groups, _ = _extract_groups_with_labels(df, group_col, data_col; force_numeric_data=force_num)
    return JonckheereTerpstraTest(groups)
end

"""
    CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol; scores=:equidistant)

Perform Cochran-Armitage test for trend in proportions on raw dataframe.
- `group_col` (IV): Must be Ordered Categorical.
- `data_col` (DV): Must be Binary.
"""
function CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
    _validate_columns(df, group_col => :ordered, data_col => :binary)
    tbl = _pivot_freq_table(df, data_col, group_col, nothing) # Rows: DV, Cols: IV (Ordered)
    
    success = Vector{Int}(tbl[2, :])
    total = Vector{Int}(sum(tbl, dims=1)[:])
    return CochranArmitageTest(success, total; kwargs...)
end

"""
    CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol, freq_col::Symbol; scores=:equidistant)

Perform Cochran-Armitage test for trend in proportions on freq dataframe.
- `group_col` (IV): Must be Ordered Categorical.
- `data_col` (DV): Must be Binary.
- `freq_col` (Frequencies): Must be numeric.
"""
function CochranArmitageTest(df::DataFrame, group_col::Symbol, data_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, group_col => :ordered, data_col => :binary, freq_col => :numeric)
    tbl = _pivot_freq_table(df, data_col, group_col, freq_col)
    
    success = Vector{Int}(tbl[2, :])
    total = Vector{Int}(sum(tbl, dims=1)[:])
    return CochranArmitageTest(success, total; kwargs...)
end

"""
    LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Perform Linear-by-Linear Association test.
- `row_col` (IV): Must be Ordered Categorical.
- `col_col` (DV): Must be Ordered Categorical.
"""
function LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :ordered, col_col => :ordered)
    tbl = _pivot_freq_table(df, row_col, col_col, nothing)
    return LinearByLinearTest(Matrix{Int}(tbl); kwargs...)
end

"""
    LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Perform Linear-by-Linear Association test.
- `row_col` (IV): Must be Ordered Categorical.
- `col_col` (DV): Must be Ordered Categorical.
- `freq_col` (Frequencies): Must be numeric.
"""
function LinearByLinearTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(df, row_col => :ordered, col_col => :ordered, freq_col => :numeric)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    return LinearByLinearTest(Matrix{Int}(tbl); kwargs...)
end