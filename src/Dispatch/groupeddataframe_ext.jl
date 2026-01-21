# groupeddataframe_ext.jl

# ==============================================================================
# Extension: Post-hoc Tests (GroupedDataFrame)
# ==============================================================================

"""
    PostHocNonPar(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
    PostHocNonPar(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol; kwargs...)

Perform non-parametric post-hoc pairwise comparisons.
- If only `data_col` is provided, groups are defined by the GroupedDataFrame keys.
- If `group_col` is provided, the grouping is reset to `group_col` (ignoring original groups).
"""
function PostHocNonPar(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
    groups, labels = _extract_groups_with_labels(gd, data_col)
    return PostHocNonPar(groups; row_labels=labels, kwargs...)
end

function PostHocNonPar(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
    return PostHocNonPar(parent(gd), group_col, data_col; kwargs...)
end

"""
    PostHocTest(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
    PostHocTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol; kwargs...)

Perform parametric post-hoc pairwise comparisons.
"""
function PostHocTest(gd::GroupedDataFrame, data_col::Symbol; kwargs...)
    groups, labels = _extract_groups_with_labels(gd, data_col)
    return PostHocTest(groups; row_labels=labels, kwargs...)
end

function PostHocTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
    return PostHocTest(parent(gd), group_col, data_col; kwargs...)
end

# --- Contingency Table Post-Hoc: Raw Data ---

"""
    PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    PostHocContingencyRow(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Perform row-wise post-hoc comparisons. 
- If `row_col` is omitted, rows are the GroupedDataFrame groups.
- If `row_col` is provided, rows are defined by `row_col` (ignoring original groups).
"""
function PostHocContingencyRow(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    tbl = _pivot_freq_table(gd, col_col)
    return PostHocContingencyRow(tbl; kwargs...)
end

function PostHocContingencyRow(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    return PostHocContingencyRow(parent(gd), row_col, col_col; kwargs...)
end

"""
    PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    PostHocContingencyCell(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Perform cell-level post-hoc analysis.
"""
function PostHocContingencyCell(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    tbl = _pivot_freq_table(gd, col_col)
    return PostHocContingencyCell(tbl; kwargs...)
end

function PostHocContingencyCell(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    return PostHocContingencyCell(parent(gd), row_col, col_col; kwargs...)
end

# ==============================================================================
# Extension: Standard Categorical Tests (GroupedDataFrame)
# ==============================================================================

"""
    ChisqTest(gd::GroupedDataFrame, col_col::Symbol)
    ChisqTest(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol)

Compute Pearson's Chi-square test.
"""
function HypothesisTests.ChisqTest(gd::GroupedDataFrame, col_col::Symbol)
    tbl = _pivot_freq_table(gd, col_col)
    r, c = size(tbl)
    if r < 2 || c < 2
        error("ChisqTest requires at least 2x2 table. Found $(r)x$(c).")
    end
    return ChisqTest(tbl)
end

function HypothesisTests.ChisqTest(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol)
    return ChisqTest(parent(gd), row_col, col_col)
end

"""
    FisherExactTest(gd::GroupedDataFrame, col_col::Symbol)
    FisherExactTest(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol)

Compute Fisher's Exact Test (2x2 only).
"""
function HypothesisTests.FisherExactTest(gd::GroupedDataFrame, col_col::Symbol)
    tbl = _pivot_freq_table(gd, col_col)
    r, c = size(tbl)
    if r != 2 || c != 2
        error("FisherExactTest currently only supports 2x2 tables. Found $(r)x$(c).")
    end
    return FisherExactTest(vec(tbl')...)
end

function HypothesisTests.FisherExactTest(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol)
    return FisherExactTest(parent(gd), row_col, col_col)
end

"""
    FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol)
    FisherExactTestRxC(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol)

Compute Fisher's Exact Test for general RxC tables.
"""
function FisherExactTestRxC(gd::GroupedDataFrame, col_col::Symbol)
    tbl = _pivot_freq_table(gd, col_col)
    return FisherExactTestRxC(tbl)
end

function FisherExactTestRxC(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol)
    return FisherExactTestRxC(parent(gd), row_col, col_col)
end

"""
    PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    PowerDivergenceTest(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Compute Power Divergence Test.
"""
function HypothesisTests.PowerDivergenceTest(gd::GroupedDataFrame, col_col::Symbol; kwargs...)
    tbl = _pivot_freq_table(gd, col_col)
    r, c = size(tbl)
    if r < 2 || c < 2
        error("PowerDivergenceTest requires at least 2x2 table. Found $(r)x$(c).")
    end
    return PowerDivergenceTest(tbl; kwargs...)
end

function HypothesisTests.PowerDivergenceTest(gd::GroupedDataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    return PowerDivergenceTest(parent(gd), row_col, col_col; kwargs...)
end

# ==============================================================================
# Extension: K-Sample & Variance Tests (GroupedDataFrame)
# ==============================================================================

"""
    OneWayANOVATest(gd::GroupedDataFrame, data_col::Symbol)
    OneWayANOVATest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)

Perform One-Way ANOVA.
"""
function HypothesisTests.OneWayANOVATest(gd::GroupedDataFrame, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return OneWayANOVATest(groups...)
end

function HypothesisTests.OneWayANOVATest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)
    return OneWayANOVATest(parent(gd), group_col, data_col)
end

"""
    WelchANOVATest(gd::GroupedDataFrame, data_col::Symbol)
    WelchANOVATest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)

Perform Welch's ANOVA.
"""
function WelchANOVATest(gd::GroupedDataFrame, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return WelchANOVATest(groups...)
end

function WelchANOVATest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)
    return WelchANOVATest(parent(gd), group_col, data_col)
end

"""
    KruskalWallisTest(gd::GroupedDataFrame, data_col::Symbol)
    KruskalWallisTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)

Perform Kruskal-Wallis Rank Sum Test.
"""
function HypothesisTests.KruskalWallisTest(gd::GroupedDataFrame, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return KruskalWallisTest(groups...)
end

function HypothesisTests.KruskalWallisTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)
    return KruskalWallisTest(parent(gd), group_col, data_col)
end

"""
    LeveneTest(gd::GroupedDataFrame, data_col::Symbol)
    LeveneTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)

Perform Levene's Test.
"""
function HypothesisTests.LeveneTest(gd::GroupedDataFrame, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return LeveneTest(groups...)
end

function HypothesisTests.LeveneTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)
    return LeveneTest(parent(gd), group_col, data_col)
end

"""
    BrownForsytheTest(gd::GroupedDataFrame, data_col::Symbol)
    BrownForsytheTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)

Perform Brown-Forsythe Test.
"""
function HypothesisTests.BrownForsytheTest(gd::GroupedDataFrame, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return BrownForsytheTest(groups...)
end

function HypothesisTests.BrownForsytheTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)
    return BrownForsytheTest(parent(gd), group_col, data_col)
end

"""
    FlignerKilleenTest(gd::GroupedDataFrame, data_col::Symbol)
    FlignerKilleenTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)

Perform Fligner-Killeen Test.
"""
function HypothesisTests.FlignerKilleenTest(gd::GroupedDataFrame, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(gd, data_col)
    return FlignerKilleenTest(groups...)
end

function HypothesisTests.FlignerKilleenTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)
    return FlignerKilleenTest(parent(gd), group_col, data_col)
end

# ==============================================================================
# Extension: 2-Sample Tests (GroupedDataFrame)
# ==============================================================================

"""
    EqualVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
    EqualVarianceTTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)

Perform Student's T-Test (equal variance).
"""
function HypothesisTests.EqualVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
    x, y = _extract_two_groups(gd, data_col)
    return EqualVarianceTTest(x, y)
end

function HypothesisTests.EqualVarianceTTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)
    return EqualVarianceTTest(parent(gd), group_col, data_col)
end

"""
    UnequalVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
    UnequalVarianceTTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)

Perform Welch's T-Test (unequal variance).
"""
function HypothesisTests.UnequalVarianceTTest(gd::GroupedDataFrame, data_col::Symbol)
    x, y = _extract_two_groups(gd, data_col)
    return UnequalVarianceTTest(x, y)
end

function HypothesisTests.UnequalVarianceTTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)
    return UnequalVarianceTTest(parent(gd), group_col, data_col)
end

"""
    VarianceFTest(gd::GroupedDataFrame, data_col::Symbol)
    VarianceFTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)

Perform F-Test for variances.
"""
function HypothesisTests.VarianceFTest(gd::GroupedDataFrame, data_col::Symbol)
    x, y = _extract_two_groups(gd, data_col)
    return VarianceFTest(x, y)
end

function HypothesisTests.VarianceFTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)
    return VarianceFTest(parent(gd), group_col, data_col)
end

"""
    MannWhitneyUTest(gd::GroupedDataFrame, data_col::Symbol)
    MannWhitneyUTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)

Perform Mann-Whitney U Test.
"""
function HypothesisTests.MannWhitneyUTest(gd::GroupedDataFrame, data_col::Symbol)
    x, y = _extract_two_groups(gd, data_col)
    return MannWhitneyUTest(x, y)
end

function HypothesisTests.MannWhitneyUTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)
    return MannWhitneyUTest(parent(gd), group_col, data_col)
end

"""
    ApproximateTwoSampleKSTest(gd::GroupedDataFrame, data_col::Symbol)
    ApproximateTwoSampleKSTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)

Perform Approximate Two-Sample KS Test.
"""
function HypothesisTests.ApproximateTwoSampleKSTest(gd::GroupedDataFrame, data_col::Symbol)
    x, y = _extract_two_groups(gd, data_col)
    return ApproximateTwoSampleKSTest(x, y)
end

function HypothesisTests.ApproximateTwoSampleKSTest(gd::GroupedDataFrame, group_col::Symbol, data_col::Symbol)
    return ApproximateTwoSampleKSTest(parent(gd), group_col, data_col)
end
