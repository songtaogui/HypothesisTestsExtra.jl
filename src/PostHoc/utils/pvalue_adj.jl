# src/PostHoc/utils/pvalue_adj.jl

"""
    parse_method_adjustment(method::Symbol)
    
Parse a method symbol with optional adjustment suffix.
Examples:
  :chisq              -> (:chisq, :none)
  :chisq_bonferroni   -> (:chisq, :bonferroni)
  :chisq_bh           -> (:chisq, :bh)
  :chisq_fdr          -> (:chisq, :bh)
"""
function parse_method_adjustment(method::Symbol)
    s = String(method)
    parts = split(s, "_")
    base = Symbol(parts[1])

    if length(parts) == 1
        return base, :none
    end

    adj_str = join(parts[2:end], "_")
    if adj_str == "bonferroni"
        return base, :bonferroni
    elseif adj_str == "bh" || adj_str == "fdr"
        return base, :bh
    else
        error("Unknown adjustment suffix in method :$method. Supported suffixes: _bonferroni, _bh, _fdr")
    end
end


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
