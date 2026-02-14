# src/PostHoc/utils/pvalue_adj.jl


"""
    adjust_pvalues(pvals::Vector{Float64}, method::Symbol)

Adjust a vector of p-values for multiple comparisons to control the family-wise error rate or false discovery rate.

# Arguments
- `pvals`: A vector of raw p-values.
- `method`: The adjustment method.
    - `:bonferroni`: Bonferroni correction (p * n). Strong control of FWER.
    - `:bh` (or `:fdr`): Benjamini-Hochberg procedure. Controls False Discovery Rate.
    - `:none`: Returns p-values unchanged.
"""
function adjust_pvalues(pvals::Vector{Float64}, method::Symbol)
    n = length(pvals)
    if n <= 1
        return pvals
    end

    adj_p = copy(pvals)

    if method == :bonferroni
        adj_p .= min.(1.0, pvals .* n)
    elseif method == :bh || method == :fdr
        # Benjamini-Hochberg procedure
        perm = sortperm(pvals)
        inv_perm = sortperm(perm)
        sorted_p = pvals[perm]

        cummin_val = 1.0
        for i in n:-1:1
            val = sorted_p[i] * (n / i)
            cummin_val = min(cummin_val, val)
            sorted_p[i] = min(1.0, cummin_val)
        end
        adj_p = sorted_p[inv_perm]
    elseif method == :none
        return pvals
    else
        error("Unknown adjustment method: :$method. Supported: :bonferroni, :bh (fdr), :none")
    end
    return adj_p
end
