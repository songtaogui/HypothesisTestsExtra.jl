# Shared DataFrame formatters for result objects

function DataFrames.DataFrame(res::PostHocTestResult)
    get_label(idx::Int) = get(res.label_map, idx, string(idx))
    n = length(res.comparisons)
    contrasts = Vector{String}(undef, n)
    diffs = Vector{Float64}(undef, n)
    ses = Vector{Float64}(undef, n)
    stats = Vector{Float64}(undef, n)
    crits = Vector{Float64}(undef, n)
    p_values = Vector{Float64}(undef, n)
    lower_cis = Vector{Float64}(undef, n)
    upper_cis = Vector{Float64}(undef, n)
    sigs = Vector{String}(undef, n)
    notes = Vector{String}(undef, n)

    for (i, c) in enumerate(res.comparisons)
        l1 = get_label(c.group1)
        l2 = get_label(c.group2)
        contrasts[i] = "$l1 - $l2"

        diffs[i] = c.diff
        ses[i] = c.se
        stats[i] = c.statistic
        crits[i] = c.crit_val
        p_values[i] = c.p_value
        lower_cis[i] = c.lower_ci
        upper_cis[i] = c.upper_ci
        sigs[i] = c.rejected ? "*" : ""
        notes[i] = c.note
    end

    return DataFrame(
        "Contrast"    => contrasts,
        "Diff"        => diffs,
        "Std.Err"     => ses,
        "Stat"        => stats,
        "Critical"    => crits,
        "P-value"     => p_values,
        "Lower 95%"   => lower_cis,
        "Upper 95%"   => upper_cis,
        "Sig"         => sigs,
        "Note"        => notes
    )
end

function DataFrames.DataFrame(res::ContingencyCellTestResult)
    rows, cols = size(res.observed)
    n_total = rows * cols

    r_labels = Vector{String}(undef, n_total)
    c_labels = Vector{String}(undef, n_total)
    observed = Vector{Int}(undef, n_total)
    stats    = Vector{Float64}(undef, n_total)
    pvals    = Vector{Float64}(undef, n_total)
    adj_pvals= Vector{Float64}(undef, n_total)
    is_sig   = Vector{Bool}(undef, n_total)

    idx = 1
    for i in 1:rows
        for j in 1:cols
            r_labels[idx]  = res.row_labels[i]
            c_labels[idx]  = res.col_labels[j]
            observed[idx]  = res.observed[i, j]
            stats[idx]     = res.stats_matrix[i, j]
            pvals[idx]     = res.pvals_matrix[i, j]
            adj_pvals[idx] = res.adj_pvals_matrix[i, j]
            is_sig[idx]    = res.sig_matrix[i, j]
            idx += 1
        end
    end

    stat_col_name = (res.method == :asr) ? "ASR (Z)" : "OddsRatio"

    return DataFrame(
        "Row"           => r_labels,
        "Column"        => c_labels,
        "Observed"      => observed,
        stat_col_name   => stats,
        "P-value"       => pvals,
        "Adj. P-value"  => adj_pvals,
        "Significant"   => is_sig
    )
end

function CellTestToDataframe(res::ContingencyCellTestResult)
    rows, cols = size(res.observed)

    df = DataFrame(RowLabel = res.row_labels)

    for j in 1:cols
        col_label = res.col_labels[j]
        col_data = Vector{String}(undef, rows)

        for i in 1:rows
            val = res.stats_matrix[i, j]
            is_sig = res.sig_matrix[i, j]
            sig_mark = is_sig ? "*" : ""
            col_data[i] = @sprintf("%.2f%s", val, sig_mark)
        end

        df[!, col_label] = col_data
    end

    return df
end

function GroupTestToDataframe(res::PostHocTestResult)
    group_indices = collect(keys(res.label_map))

    if isempty(group_indices) && !isempty(res.cld_letters)
        group_indices = collect(keys(res.cld_letters))
    end

    sort!(group_indices)

    labels = [get(res.label_map, g, string(g)) for g in group_indices]
    letters = [get(res.cld_letters, g, "") for g in group_indices]

    return DataFrame(
        GroupIndex = group_indices,
        GroupLabel = labels,
        CLD = letters
    )
end
