# src/PostHoc/utils/ranking.jl


function calculate_ranks(groups::AbstractVector{<:AbstractVector{<:Real}})
    data_flat = Float64[]
    group_ids = Int[]
    for (i, g) in enumerate(groups)
        append!(data_flat, g)
        append!(group_ids, fill(i, length(g)))
    end
    
    N = length(data_flat)
    p = sortperm(data_flat)
    sorted_data = data_flat[p]
    ranks = zeros(Float64, N)
    
    i = 1
    while i <= N
        j = i
        while j < N && sorted_data[j+1] == sorted_data[i]
            j += 1
        end
        avg_rank = (i + j) / 2.0
        for k in i:j
            ranks[p[k]] = avg_rank
        end
        i = j + 1
    end
    
    counts = Dict{Float64, Int}()
    for x in data_flat
        counts[x] = get(counts, x, 0) + 1
    end
    
    sum_T = 0.0
    for t in values(counts)
        if t > 1
            sum_T += (t^3 - t)
        end
    end
    tie_corr = 1.0 - sum_T / (N^3 - N)
    if tie_corr == 0 
        tie_corr = 1.0 
    end

    group_ranks = [Float64[] for _ in 1:length(groups)]
    for idx in 1:N
        gid = group_ids[idx]
        push!(group_ranks[gid], ranks[idx])
    end
    
    return group_ranks, tie_corr, N
end
