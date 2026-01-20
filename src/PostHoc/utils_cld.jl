# PostHoc/utils_cld.jl

# ==============================================================================
# CLD (Compact Letter Display) Generator
# ==============================================================================

function generate_cld(means::Vector{Float64}, comparisons::Vector{PostHocComparison}, alpha::Float64)
    if alpha <= 0 || alpha >= 1
        error("Alpha must be between 0 and 1. Received: $alpha")
    end

    if alpha > 0.1
        @warn "Alpha ($alpha) is unusually large (> 0.10). This increases the risk of Type I errors."
    end

    k = length(means)
    # Adjacency matrix: true means NO significant difference
    adj = ones(Bool, k, k)
    
    for c in comparisons
        if c.rejected
            adj[c.group1, c.group2] = false
            adj[c.group2, c.group1] = false
        end
    end
    
    # Bron-Kerbosch-like clique finding (simplified for this context)
    sorted_indices = sortperm(means, rev=true)
    temp_cliques = Vector{Vector{Int}}()
    
    for i in 1:k
        current_root = sorted_indices[i]
        clique = [current_root]
        for j in (i+1):k
            candidate = sorted_indices[j]
            connects_all = true
            for member in clique
                if !adj[member, candidate]
                    connects_all = false
                    break
                end
            end
            if connects_all
                push!(clique, candidate)
            end
        end
        push!(temp_cliques, clique)
    end
    
    # Filter maximal cliques
    sort!(temp_cliques, by=length, rev=true)
    final_cliques = Vector{Vector{Int}}()
    for c in temp_cliques
        is_subset = false
        for exist in final_cliques
            if issubset(c, exist)
                is_subset = true
                break
            end
        end
        if !is_subset
            push!(final_cliques, c)
        end
    end
    
    sort!(final_cliques, by = c -> maximum(means[c]), rev=true)
    
    use_caps = alpha <= 0.01
    base_char = use_caps ? 'A' : 'a'
    
    group_letters_map = Dict{Int, String}()
    for i in 1:k
        group_letters_map[i] = ""
    end
    
    for (idx, clique) in enumerate(final_cliques)
        # Handle cases with more than 26 groups
        if idx > 26
            letter = string(base_char) * string(idx) 
        else
            letter = string(Char(base_char + idx - 1))
        end
        
        for group_idx in clique
            group_letters_map[group_idx] *= letter
        end
    end
    return group_letters_map
end
