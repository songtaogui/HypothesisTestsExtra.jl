# src/PostHoc/engines/contingency.jl


# --- Chi-Square Method ---
"""
    _run_chisq_row(d::ContingencyData)

Runs pairwise Chi-square tests for row comparisons.
"""
function _run_chisq_row(d::ContingencyData)
    results = RawComparisonResult[]

    for (r1, r2) in d.pairs
        sub_table = d.table[[r1, r2], :]

        # Clean: Remove columns where sum is 0 to avoid DoF errors
        col_mask = vec(sum(sub_table, dims=1) .> 0)
        clean_sub = sub_table[:, col_mask]

        stat_val = 0.0
        p_val = 1.0
        note = ""

        try
            if size(clean_sub, 2) < 2
                note = "Degenerate"
            else
                ct = ChisqTest(clean_sub)
                stat_val = ct.chisq
                p_val = pvalue(ct)
            end
        catch
            p_val = 1.0
            note = "Error"
        end

        push!(results, RawComparisonResult(r1, r2, stat_val, p_val, note))
    end
    return results
end

# --- Fisher Method (Exact 2x2 or Monte Carlo RxC) ---
"""
    _run_fisher_row(d::ContingencyData)

Runs pairwise Fisher's Exact tests. Uses the `FisherExactTestRxC` smart constructor
to automatically select between the exact 2x2 test and the Monte Carlo simulation for RxC tables.
"""
function _run_fisher_row(d::ContingencyData)
    results = RawComparisonResult[]

    for (r1, r2) in d.pairs
        sub_table = d.table[[r1, r2], :]

        # Clean: Remove columns where sum is 0
        col_mask = vec(sum(sub_table, dims=1) .> 0)
        clean_sub = sub_table[:, col_mask]

        stat_val = 0.0
        p_val = 1.0
        note = ""

        cols = size(clean_sub, 2)

        if cols < 2
            note = "Degenerate"
        else
            # Use the smart constructor.
            # It returns either HypothesisTests.FisherExactTest (for 2x2)
            # or FisherExactTestMC (for 2xC where C > 2).
            ft = FisherExactTestRxC(clean_sub)
            
            p_val = pvalue(ft)
            
            # Determine statistic and note based on the returned type
            if isa(ft, FisherExactTestMC)
                # For Monte Carlo, the statistic is the log-probability metric
                stat_val = ft.log_prob_obs 
                note = "MC RxC"
            else
                # For Standard 2x2, use the Odds Ratio (omega)
                stat_val = ft.omega
                note = "Exact 2x2"
            end
        end

        push!(results, RawComparisonResult(r1, r2, stat_val, p_val, note))
    end
    return results
end

const CONTINGENCY_METHOD_DISPATCH = Dict(
    :chisq => _run_chisq_row,
    :fisher => _run_fisher_row
)
