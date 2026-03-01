# src/Dispatch/groupeddataframe_ext.jl

# ==============================================================================
# Extension: Post-hoc Tests (GroupedDataFrame)
# ==============================================================================

"""
    PostHocNonPar(gd::GroupedDataFrame, data_col::Symbol; kwargs...)

Non-parametric post-hoc pairwise comparisons (e.g., Dunn's test).
Groups are defined by the `GroupedDataFrame` keys.
Type requirements: `data_col` must be Numeric or Ordered Categorical.
"""
function PostHocNonPar(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
    parent_df = parent(gd)
    # Validate DV
    _assert_requirement(
        _is_numeric(parent_df[!, data_col]) || _is_ordered(parent_df[!, data_col]),
        "Column :$data_col must be numeric or ordered."
    )
    
    force_num = _is_ordered(parent_df[!, data_col])
    groups, labels = _extract_groups_with_labels(gd, data_col; force_numeric_data=force_num)
    return PostHocNonPar(groups; row_labels=labels, kwargs...)
end

"""
    PostHocPar(gd::GroupedDataFrame, data_col::Symbol; kwargs...)

Perform parametric post-hoc pairwise comparisons (e.g., Tukey's HSD).
Groups are defined by the `GroupedDataFrame` keys.
Type requirements: `data_col` must be Numeric.
"""
function PostHocPar(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, labels = _extract_groups_with_labels(gd, data_col)
    return PostHocPar(groups; row_labels=labels, kwargs...)
end

# --- Contingency Table Post-Hoc: Raw & Frequency ---

"""
    PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)

Perform row-wise post-hoc comparisons. Rows are defined by `gd` groups.
"""
function PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl = _pivot_freq_table(gd, col_col, nothing)
    return PostHocContingencyRow(tbl; kwargs...)
end

function PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(gd, col_col, freq_col)
    return PostHocContingencyRow(tbl; kwargs...)
end

"""
    PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)

Perform cell-level post-hoc analysis (ASR). Rows are defined by `gd` groups.
"""
function PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl = _pivot_freq_table(gd, col_col, nothing)
    return PostHocContingencyCell(tbl; kwargs...)
end

function PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(gd, col_col, freq_col)
    return PostHocContingencyCell(tbl; kwargs...)
end

# ==============================================================================
# Extension: Standard Categorical Tests (GroupedDataFrame)
# ==============================================================================

"""
    ChisqTest(gd::GroupedDataFrame, col_col::Symbol)
    ChisqTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)

Compute Pearson's Chi-square test. Rows are defined by `gd` groups.
"""
function HypothesisTests.ChisqTest(gd::GroupedDataFrame, col_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl = _pivot_freq_table(gd, col_col, nothing)
    _assert_requirement(all(size(tbl) .>= 2), "ChisqTest requires at least 2x2 table.")
    return ChisqTest(tbl)
end

function HypothesisTests.ChisqTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(gd, col_col, freq_col)
    return ChisqTest(tbl)
end

"""
    FisherExactTest(gd::GroupedDataFrame, col_col::Symbol)
    FisherExactTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)

Compute Fisher's Exact Test (2x2 only). Rows are defined by `gd` groups.
"""
function HypothesisTests.FisherExactTest(gd::GroupedDataFrame, col_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl = _pivot_freq_table(gd, col_col, nothing)
    _assert_requirement(size(tbl) == (2, 2), "FisherExactTest requires a 2x2 table.")
    return FisherExactTest(vec(tbl')...)
end

function HypothesisTests.FisherExactTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(gd, col_col, freq_col)
    _assert_requirement(size(tbl) == (2, 2), "FisherExactTest requires a 2x2 table.")
    return FisherExactTest(vec(tbl')...)
end

"""
    FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol)
    FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)

Compute Fisher's Exact Test for general RxC tables.
"""
function FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl = _pivot_freq_table(gd, col_col, nothing)
    return FisherExactTestRxC(tbl)
end

function FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(gd, col_col, freq_col)
    return FisherExactTestRxC(tbl)
end

"""
    PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)

Compute Power Divergence Test.
"""
function HypothesisTests.PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    _validate_columns(parent(gd), col_col => :categorical)
    tbl = _pivot_freq_table(gd, col_col, nothing)
    _assert_requirement(all(size(tbl) .>= 2), "PowerDivergenceTest requires at least 2x2 table.")
    return PowerDivergenceTest(tbl; kwargs...)
end

function HypothesisTests.PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)
    _validate_columns(parent(gd), col_col => :categorical, freq_col => :numeric)
    tbl = _pivot_freq_table(gd, col_col, freq_col)
    return PowerDivergenceTest(tbl; kwargs...)
end

# ==============================================================================
# Extension: K-Sample & Variance Tests (GroupedDataFrame)
# ==============================================================================

"""
    OneWayANOVATest(gd::GroupedDataFrame, data_col::Symbol)

Perform One-Way ANOVA. `gd` groups define the independent variable.
"""
function HypothesisTests.OneWayANOVATest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return OneWayANOVATest(groups...)
end

"""
    WelchANOVATest(gd::GroupedDataFrame, data_col::Symbol)

Perform Welch's ANOVA.
"""
function WelchANOVATest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return WelchANOVATest(groups...)
end

"""
    KruskalWallisTest(gd::GroupedDataFrame, data_col::Symbol)

Perform Kruskal-Wallis Rank Sum Test. Supports Numeric or Ordered DV.
"""
function HypothesisTests.KruskalWallisTest(gd::GroupedDataFrame, data_col::Symbol)
    parent_df = parent(gd)
    _assert_requirement(
        _is_numeric(parent_df[!, data_col]) || _is_ordered(parent_df[!, data_col]),
        "KruskalWallis requires numeric or ordered DV."
    )
    force_num = _is_ordered(parent_df[!, data_col])
    groups, _ = _extract_groups_with_labels(gd, data_col; force_numeric_data=force_num)
    return KruskalWallisTest(groups...)
end

"""
    LeveneTest(gd::GroupedDataFrame, data_col::Symbol)

Perform Levene's Test for homogeneity of variance.
"""
function HypothesisTests.LeveneTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return LeveneTest(groups...)
end

"""
    BrownForsytheTest(gd::GroupedDataFrame, data_col::Symbol)

Perform Brown-Forsythe Test.
"""
function HypothesisTests.BrownForsytheTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return BrownForsytheTest(groups...)
end

"""
    FlignerKilleenTest(gd::GroupedDataFrame, data_col::Symbol)

Perform Fligner-Killeen Test.
"""
function HypothesisTests.FlignerKilleenTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return FlignerKilleenTest(groups...)
end

# ==============================================================================
# Extension: 2-Sample Tests (GroupedDataFrame)
# ==============================================================================

"""
    EqualVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)

Perform Student's T-Test. `gd` must contain exactly 2 groups.
"""
function HypothesisTests.EqualVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return EqualVarianceTTest(x, y)
end

"""
    UnequalVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)

Perform Welch's T-Test (unequal variance). `gd` must contain exactly 2 groups.
"""
function HypothesisTests.UnequalVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return UnequalVarianceTTest(x, y)
end

"""
    HypothesisTests.SignTest(gd::GroupedDataFrame, data_col::Symbol, median::Real = 0)

Perform paired Sign Test on a GroupedDataFrame with exactly 2 groups.
- `data_col`: Must be numeric.
- `median`: Null median of paired differences (default `0`).
"""
function HypothesisTests.SignTest(gd::GroupedDataFrame, data_col::Symbol, median::Real = 0)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.SignTest(x, y, median)
end

"""
    HypothesisTests.SignedRankTest(gd::GroupedDataFrame, data_col::Symbol)

Perform Wilcoxon Signed-Rank Test on a GroupedDataFrame with exactly 2 groups.
- `data_col`: Must be numeric.
"""
function HypothesisTests.SignedRankTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return HypothesisTests.SignedRankTest(x, y)
end

"""
    VarianceFTest(gd::GroupedDataFrame, data_col::Symbol)

Perform F-Test for variances. `gd` must contain exactly 2 groups.
"""
function HypothesisTests.VarianceFTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return VarianceFTest(x, y)
end

"""
    MannWhitneyUTest(gd::GroupedDataFrame, data_col::Symbol)

Perform Mann-Whitney U Test. `gd` must contain exactly 2 groups.
Supports Numeric or Ordered DV.
"""
function HypothesisTests.MannWhitneyUTest(gd::GroupedDataFrame, data_col::Symbol)
    parent_df = parent(gd)
    _assert_requirement(
        _is_numeric(parent_df[!, data_col]) || _is_ordered(parent_df[!, data_col]),
        "MannWhitneyU requires numeric or ordered DV."
    )
    force_num = _is_ordered(parent_df[!, data_col])
    x, y = _extract_two_groups(gd, data_col; force_numeric_data=force_num)
    return MannWhitneyUTest(x, y)
end

"""
    ApproximateTwoSampleKSTest(gd::GroupedDataFrame, data_col::Symbol)

Perform Approximate Two-Sample KS Test. `gd` must contain exactly 2 groups.
"""
function HypothesisTests.ApproximateTwoSampleKSTest(gd::GroupedDataFrame, data_col::Symbol)
    _validate_columns(parent(gd), data_col => :numeric)
    x, y = _extract_two_groups(gd, data_col)
    return ApproximateTwoSampleKSTest(x, y)
end

# ==============================================================================
# Extension: Trend and Association Tests (GroupedDataFrame)
# ==============================================================================

"""
    JonckheereTerpstraTest(gd::GroupedDataFrame, data_col::Symbol)

Perform Jonckheere-Terpstra test. 
The GroupedDataFrame keys must be Ordered Categorical.
`data_col` must be Numeric or Ordered.
"""
function JonckheereTerpstraTest(gd::GroupedDataFrame, data_col::Symbol)
    parent_df = parent(gd)
    g_cols = groupcols(gd)
    
    # Validate IV (Ordered) and DV (Numeric/Ordered)
    _assert_requirement(_is_ordered(parent_df[!, g_cols[1]]), "Jonckheere-Terpstra requires ordered groups.")
    _assert_requirement(
        _is_numeric(parent_df[!, data_col]) || _is_ordered(parent_df[!, data_col]), 
        "Jonckheere-Terpstra requires numeric or ordered DV.")
    
    force_num = _is_ordered(parent_df[!, data_col])
    groups, _ = _extract_groups_with_labels(gd, data_col; force_numeric_data=force_num)
    return JonckheereTerpstraTest(groups)
end

"""
    CochranArmitageTest(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
    CochranArmitageTest(gd::GroupedDataFrame, data_col::Symbol, freq_col::Symbol; kwargs...)

Perform Cochran-Armitage test for trend. 
`gd` keys must be Ordered. `data_col` must be Binary.
"""
function CochranArmitageTest(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
    parent_df = parent(gd)
    g_cols = groupcols(gd)
    _validate_columns(parent_df, data_col => :binary)
    _assert_requirement(_is_ordered(parent_df[!, g_cols[1]]), "Cochran-Armitage requires ordered groups.")
    
    tbl = _pivot_freq_table(gd, data_col, nothing)
    success = Vector{Int}(tbl[2, :])
    total = Vector{Int}(sum(tbl, dims=1)[:])
    return CochranArmitageTest(success, total; kwargs...)
end

function CochranArmitageTest(gd::GroupedDataFrame, data_col::Symbol, freq_col::Symbol; kwargs...)
    parent_df = parent(gd)
    g_cols = groupcols(gd)
    _validate_columns(parent_df, data_col => :binary, freq_col => :numeric)
    _assert_requirement(_is_ordered(parent_df[!, g_cols[1]]), "Cochran-Armitage requires ordered groups.")
    
    tbl = _pivot_freq_table(gd, data_col, freq_col)
    success = Vector{Int}(tbl[2, :])
    total = Vector{Int}(sum(tbl, dims=1)[:])
    return CochranArmitageTest(success, total; kwargs...)
end

"""
    LinearByLinearTest(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    LinearByLinearTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)

Perform Linear-by-Linear Association test.
Both `gd` groups and `col_col` must be Ordered Categorical.
"""
function LinearByLinearTest(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    parent_df = parent(gd)
    g_cols = groupcols(gd)
    _validate_columns(parent_df, col_col => :ordered)
    _assert_requirement(_is_ordered(parent_df[!, g_cols[1]]), "Linear-by-Linear requires ordered groups.")
    
    tbl = _pivot_freq_table(gd, col_col, nothing)
    return LinearByLinearTest(Matrix{Int}(tbl); kwargs...)
end

function LinearByLinearTest(gd::GroupedDataFrame, col_col::Symbol, freq_col::Symbol; kwargs...)
    parent_df = parent(gd)
    g_cols = groupcols(gd)
    _validate_columns(parent_df, col_col => :ordered, freq_col => :numeric)
    _assert_requirement(_is_ordered(parent_df[!, g_cols[1]]), "Linear-by-Linear requires ordered groups.")
    
    tbl = _pivot_freq_table(gd, col_col, freq_col)
    return LinearByLinearTest(Matrix{Int}(tbl); kwargs...)
end
