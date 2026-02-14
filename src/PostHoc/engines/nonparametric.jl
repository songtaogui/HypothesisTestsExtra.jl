# src/PostHoc/engines/nonparametric.jl


function _run_dunn(d::KWStatData, adjustment::Symbol)
    comparisons = PostHocComparison[]
    num_tests = length(d.pairs)
    base_variance = (d.n_total * (d.n_total + 1) / 12.0) * d.tie_correction
    
    adj_alpha = d.alpha
    note_str = "None"
    
    if adjustment == :bonferroni
        adj_alpha = d.alpha / num_tests
        note_str = "Bonferroni"
    elseif adjustment == :sidak
        adj_alpha = 1.0 - (1.0 - d.alpha)^(1/num_tests)
        note_str = "Sidak"
    end
    
    dist = Normal(0, 1)
    crit = quantile(dist, 1 - adj_alpha/2)
    
    for (i, j) in d.pairs
        diff = d.mean_ranks[i] - d.mean_ranks[j]
        se = sqrt(base_variance * (1/d.ns[i] + 1/d.ns[j]))
        z_stat = abs(diff) / se
        raw_pval = 2 * ccdf(dist, z_stat)
        
        final_pval = raw_pval
        if adjustment == :bonferroni
            final_pval = min(1.0, raw_pval * num_tests)
        elseif adjustment == :sidak
            final_pval = 1.0 - (1.0 - raw_pval)^num_tests
        end
        
        margin = crit * se
        push!(comparisons, PostHocComparison(
            i, j, diff, se, z_stat, crit, final_pval, 
            diff - margin, diff + margin, final_pval < d.alpha, "Adj: $note_str"
        ))
    end
    return comparisons
end

function _run_nemenyi(d::KWStatData)
    comparisons = PostHocComparison[]
    k = d.k
    base_variance = (d.n_total * (d.n_total + 1) / 12.0) * d.tie_correction
    q_crit = Rmath.qtukey(1.0 - d.alpha, k, Inf, 1)
    crit_val_scaled = q_crit / sqrt(2)
    
    for (i, j) in d.pairs
        diff = d.mean_ranks[i] - d.mean_ranks[j]
        se = sqrt(base_variance * (1/d.ns[i] + 1/d.ns[j]))
        stat = abs(diff) / se 
        pval = 1.0 - Rmath.ptukey(stat * sqrt(2), k, Inf, 1)
        margin = crit_val_scaled * se
        push!(comparisons, PostHocComparison(
            i, j, diff, se, stat, crit_val_scaled, pval, 
            diff - margin, diff + margin, pval < d.alpha, "Nemenyi"
        ))
    end
    return comparisons
end
