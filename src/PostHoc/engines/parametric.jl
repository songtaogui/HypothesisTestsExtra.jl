# src/PostHoc/engines/parametric.jl


# ==============================================================================
# Parametric Post-hoc Algorithms
# ==============================================================================

# Helper to iterate only over requested pairs
function _iter_pairs(d::StatData)
    return d.pairs
end

# --- LSD ---
function _run_lsd(d::StatData)
    comparisons = PostHocComparison[]
    dist = TDist(d.df_resid)
    crit = quantile(dist, 1 - d.alpha/2)
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.mse * (1/d.ns[i] + 1/d.ns[j]))
        stat = abs(diff) / se
        pval = 2 * ccdf(dist, stat)
        margin = crit * se
        push!(comparisons, PostHocComparison(i, j, diff, se, stat, crit, pval, diff-margin, diff+margin, pval < d.alpha, ""))
    end
    return comparisons
end

# --- Bonferroni ---
function _run_bonferroni(d::StatData)
    comparisons = PostHocComparison[]
    num_tests = length(d.pairs)
    
    dist = TDist(d.df_resid)
    adj_alpha = d.alpha / num_tests
    crit = quantile(dist, 1 - adj_alpha/2)
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.mse * (1/d.ns[i] + 1/d.ns[j]))
        stat = abs(diff) / se
        raw_pval = 2 * ccdf(dist, stat)
        pval = min(1.0, raw_pval * num_tests)
        margin = crit * se
        push!(comparisons, PostHocComparison(i, j, diff, se, stat, crit, pval, diff-margin, diff+margin, pval < d.alpha, "m=$num_tests"))
    end
    return comparisons
end

# --- Sidak ---
function _run_sidak(d::StatData)
    comparisons = PostHocComparison[]
    num_tests = length(d.pairs)
    
    dist = TDist(d.df_resid)
    adj_alpha = 1.0 - (1.0 - d.alpha)^(1/num_tests)
    crit = quantile(dist, 1 - adj_alpha/2)
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.mse * (1/d.ns[i] + 1/d.ns[j]))
        stat = abs(diff) / se
        raw_pval = 2 * ccdf(dist, stat)
        pval = 1.0 - (1.0 - raw_pval)^num_tests
        margin = crit * se
        push!(comparisons, PostHocComparison(i, j, diff, se, stat, crit, pval, diff-margin, diff+margin, pval < d.alpha, "m=$num_tests"))
    end
    return comparisons
end

# --- Scheffe ---
function _run_scheffe(d::StatData)
    comparisons = PostHocComparison[]
    f_dist = FDist(d.k-1, d.df_resid)
    crit = sqrt((d.k-1) * quantile(f_dist, 1 - d.alpha))
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.mse * (1/d.ns[i] + 1/d.ns[j]))
        stat = abs(diff) / se
        pval = ccdf(f_dist, stat^2 / (d.k-1))
        margin = crit * se
        push!(comparisons, PostHocComparison(i, j, diff, se, stat, crit, pval, diff-margin, diff+margin, pval < d.alpha, ""))
    end
    return comparisons
end

# --- Tukey HSD ---
function _run_tukey(d::StatData)
    comparisons = PostHocComparison[]
    q_crit = Rmath.qtukey(1.0 - d.alpha, d.k, d.df_resid, 1)
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.mse * (1/d.ns[i] + 1/d.ns[j]))
        q_stat = abs(diff) / (se / sqrt(2))
        pval = 1.0 - Rmath.ptukey(q_stat, d.k, d.df_resid, 1)
        margin = (q_crit / sqrt(2)) * se
        push!(comparisons, PostHocComparison(i, j, diff, se, q_stat, q_crit, pval, diff-margin, diff+margin, pval < d.alpha, ""))
    end
    return comparisons
end

# --- Tamhane T2 ---
function _run_tamhane(d::StatData)
    comparisons = PostHocComparison[]
    num_tests = length(d.pairs)
    adj_alpha = 1.0 - (1.0 - d.alpha)^(1/num_tests)
    
    for (i, j) in _iter_pairs(d)
        diff = d.means[i] - d.means[j]
        se = sqrt(d.vars[i]/d.ns[i] + d.vars[j]/d.ns[j])
        df_pair = (d.vars[i]/d.ns[i] + d.vars[j]/d.ns[j])^2 / 
                  ((d.vars[i]/d.ns[i])^2/(d.ns[i]-1) + (d.vars[j]/d.ns[j])^2/(d.ns[j]-1))
        
        dist = TDist(df_pair)
        crit = quantile(dist, 1 - adj_alpha/2)
        stat = abs(diff) / se
        raw_pval = 2 * ccdf(dist, stat)
        pval = 1.0 - (1.0 - raw_pval)^num_tests
        margin = crit * se
        push!(comparisons, PostHocComparison(i, j, diff, se, stat, crit, pval, diff-margin, diff+margin, pval < d.alpha, "Welch+Sidak"))
    end
    return comparisons
end

# --- SNK & Duncan ---
function _run_stepwise(d::StatData, type::Symbol)
    comparisons = PostHocComparison[]
    sorted_idx = sortperm(d.means) 
    n_harmonic = d.k / sum(1 ./ d.ns)
    se_stepwise = sqrt(d.mse / n_harmonic) 
    
    sig_map = Dict{Tuple{Int, Int}, Bool}()
    all_comps = PostHocComparison[]
    
    for p in d.k:-1:2
        for i in 1:(d.k - p + 1)
            j = i + p - 1
            idx_low = sorted_idx[i]
            idx_high = sorted_idx[j]
            
            real_diff = d.means[idx_high] - d.means[idx_low]
            abs_diff = abs(real_diff)
            real_se = sqrt(d.mse * (1/d.ns[idx_low] + 1/d.ns[idx_high]))
            
            q_stat = abs_diff / se_stepwise 
            
            if type == :snk
                q_crit = Rmath.qtukey(1.0 - d.alpha, p, d.df_resid, 1)
            else # :duncan
                alpha_p = 1.0 - (1.0 - d.alpha)^(p - 1)
                q_crit = Rmath.qtukey(1.0 - alpha_p, p, d.df_resid, 1)
            end
            
            is_sig_calc = q_stat > q_crit
            
            # Protection logic
            is_protected = false
            if p < d.k
                if j < d.k && haskey(sig_map, (i, j+1)) && !sig_map[(i, j+1)]
                    is_protected = true
                end
                if i > 1 && haskey(sig_map, (i-1, j)) && !sig_map[(i-1, j)]
                    is_protected = true
                end
            end
            
            final_sig = is_sig_calc && !is_protected
            sig_map[(i, j)] = final_sig
            
            pval = 1.0 - Rmath.ptukey(q_stat, p, d.df_resid, 1)
            margin = (q_crit / sqrt(2)) * real_se
            
            g1, g2 = idx_low < idx_high ? (idx_low, idx_high) : (idx_high, idx_low)
            d_val = d.means[g1] - d.means[g2]
            
            push!(all_comps, PostHocComparison(
                g1, g2, d_val, real_se, q_stat, q_crit, pval, 
                d_val - margin, d_val + margin, final_sig, "Span=$p"
            ))
        end
    end
    
    target_set = Set([(min(p[1], p[2]), max(p[1], p[2])) for p in d.pairs])
    for c in all_comps
        if (c.group1, c.group2) in target_set
            push!(comparisons, c)
        end
    end
    sort!(comparisons, by = x -> (x.group1, x.group2))
    return comparisons
end

function _run_snk(d::StatData) _run_stepwise(d, :snk) end
function _run_duncan(d::StatData) _run_stepwise(d, :duncan) end

const METHOD_DISPATCH = Dict(
    :lsd => _run_lsd,
    :bonferroni => _run_bonferroni,
    :sidak => _run_sidak,
    :scheffe => _run_scheffe,
    :tukey => _run_tukey,
    :tamhane => _run_tamhane,
    :snk => _run_snk,
    :duncan => _run_duncan
)
