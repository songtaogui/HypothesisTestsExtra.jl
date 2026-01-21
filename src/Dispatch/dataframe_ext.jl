# dataframe_ext.jl

# ==============================================================================
# Extension: Post-hoc Tests (DataFrame)
# ==============================================================================

"""
    PostHocNonPar(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)

Perform non-parametric post-hoc pairwise comparisons (e.g., Dunn's Test).
"""
function PostHocNonPar(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
    groups, labels = _extract_groups_with_labels(df, group_col, data_col)
    return PostHocNonPar(groups; row_labels=labels, kwargs...)
end

"""
    PostHocTest(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)

Perform parametric post-hoc pairwise comparisons (e.g., Tukey's HSD).
"""
function PostHocTest(df::DataFrame, group_col::Symbol, data_col::Symbol; kwargs...)
    groups, labels = _extract_groups_with_labels(df, group_col, data_col)
    return PostHocTest(groups; row_labels=labels, kwargs...)
end

# --- Contingency Table Post-Hoc: Raw Data ---

"""
    PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Perform row-wise post-hoc comparisons (e.g., Chi-Sq or Fisher) on raw categorical data.
"""
function PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    return PostHocContingencyRow(tbl; kwargs...)
end

"""
    PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Perform cell-level post-hoc analysis (e.g., ASR) on raw categorical data.
"""
function PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    return PostHocContingencyCell(tbl; kwargs...)
end

# --- Contingency Table Post-Hoc: Frequency Data ---

"""
    PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Perform row-wise post-hoc comparisons on aggregated frequency data (Long format).
"""
function PostHocContingencyRow(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    return PostHocContingencyRow(tbl; kwargs...)
end

"""
    PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Perform cell-level post-hoc analysis on aggregated frequency data (Long format).
"""
function PostHocContingencyCell(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
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
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    r, c = size(tbl)
    if r < 2 || c < 2
        error("ChisqTest requires at least 2x2 table. Found $(r)x$(c).")
    end
    return ChisqTest(tbl)
end

"""
    ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Compute Pearson's Chi-square test from aggregated frequency data.
"""
function HypothesisTests.ChisqTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    r, c = size(tbl)
    if r < 2 || c < 2
        error("ChisqTest requires at least 2x2 table. Found $(r)x$(c).")
    end
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
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    r, c = size(tbl)
    if r != 2 || c != 2
        error("FisherExactTest currently only supports 2x2 tables. Found $(r)x$(c).")
    end
    return FisherExactTest(vec(tbl')...)
end

"""
    FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Compute Fisher's Exact Test from aggregated frequency data (2x2 only).
"""
function HypothesisTests.FisherExactTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    r, c = size(tbl)
    if r != 2 || c != 2
        error("FisherExactTest currently only supports 2x2 tables. Found $(r)x$(c).")
    end
    return FisherExactTest(vec(tbl')...)
end

"""
    FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol)

Compute Fisher's Exact Test for general RxC tables from a raw DataFrame.
"""
function FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol)
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    return FisherExactTestRxC(tbl)
end

"""
    FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)

Compute Fisher's Exact Test (RxC) from aggregated frequency data.
"""
function FisherExactTestRxC(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    return FisherExactTestRxC(tbl)
end

"""
    PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)

Compute Power Divergence Test from a raw DataFrame.
"""
function HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol; kwargs...)
    df_clean = dropmissing(df[:, [row_col, col_col]])
    tbl = freqtable(df_clean, row_col, col_col)
    r, c = size(tbl)
    if r < 2 || c < 2
        error("PowerDivergenceTest requires at least 2x2 table. Found $(r)x$(c).")
    end
    return PowerDivergenceTest(tbl; kwargs...)
end

"""
    PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)

Compute Power Divergence Test from aggregated frequency data.
"""
function HypothesisTests.PowerDivergenceTest(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Symbol; kwargs...)
    tbl = _pivot_freq_table(df, row_col, col_col, freq_col)
    r, c = size(tbl)
    if r < 2 || c < 2
        error("PowerDivergenceTest requires at least 2x2 table. Found $(r)x$(c).")
    end
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
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return OneWayANOVATest(groups...)
end

"""
    WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Welch's ANOVA on a DataFrame.
"""
function WelchANOVATest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return WelchANOVATest(groups...)
end

"""
    KruskalWallisTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Kruskal-Wallis Rank Sum Test on a DataFrame.
"""
function HypothesisTests.KruskalWallisTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return KruskalWallisTest(groups...)
end

"""
    LeveneTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Levene's Test on a DataFrame.
"""
function HypothesisTests.LeveneTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return LeveneTest(groups...)
end

"""
    BrownForsytheTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Brown-Forsythe Test on a DataFrame.
"""
function HypothesisTests.BrownForsytheTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return BrownForsytheTest(groups...)
end

"""
    FlignerKilleenTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Fligner-Killeen Test on a DataFrame.
"""
function HypothesisTests.FlignerKilleenTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    groups, _ = _extract_groups_with_labels(df, group_col, data_col)
    return FlignerKilleenTest(groups...)
end

# ==============================================================================
# Extension: 2-Sample Tests (DataFrame)
# ==============================================================================

"""
    EqualVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Student's T-Test (equal variance) on a DataFrame (exactly 2 groups).
"""
function HypothesisTests.EqualVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    x, y = _extract_two_groups(df, group_col, data_col)
    return EqualVarianceTTest(x, y)
end

"""
    UnequalVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Welch's T-Test (unequal variance) on a DataFrame (exactly 2 groups).
"""
function HypothesisTests.UnequalVarianceTTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    x, y = _extract_two_groups(df, group_col, data_col)
    return UnequalVarianceTTest(x, y)
end

"""
    VarianceFTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform F-Test for variances on a DataFrame (exactly 2 groups).
"""
function HypothesisTests.VarianceFTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    x, y = _extract_two_groups(df, group_col, data_col)
    return VarianceFTest(x, y)
end

"""
    MannWhitneyUTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Mann-Whitney U Test on a DataFrame (exactly 2 groups).
"""
function HypothesisTests.MannWhitneyUTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    x, y = _extract_two_groups(df, group_col, data_col)
    return MannWhitneyUTest(x, y)
end

"""
    ApproximateTwoSampleKSTest(df::DataFrame, group_col::Symbol, data_col::Symbol)

Perform Approximate Two-Sample KS Test on a DataFrame (exactly 2 groups).
"""
function HypothesisTests.ApproximateTwoSampleKSTest(df::DataFrame, group_col::Symbol, data_col::Symbol)
    x, y = _extract_two_groups(df, group_col, data_col)
    return ApproximateTwoSampleKSTest(x, y)
end
