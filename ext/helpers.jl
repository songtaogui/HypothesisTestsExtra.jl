@inline _is_valid_value(x) = !ismissing(x) && !isnothing(x) && (!(x isa Number) || !isnan(x))

_get_clean_data(col) = [x for x in col if _is_valid_value(x)]

function _get_clean_df(df::AbstractDataFrame, cols::Vector{Symbol})
    return filter(row -> all(_is_valid_value(row[c]) for c in cols), df[:, cols])
end

_assert_requirement(cond::Bool, msg::String) = cond || throw(ArgumentError(msg))

function _format_group_key(key)
    vals = values(key)
    return length(vals) == 1 ? string(vals[1]) : join(string.(vals), " | ")
end

"""
    _to_count_int(x, colname::Symbol)

Convert a frequency value to Int safely.
Requires finite, non-negative, integer-valued number.
Throws ArgumentError otherwise.
"""
function _to_count_int(x, colname::Symbol)
    _assert_requirement(x isa Number, "Column :$colname must contain numeric frequency values.")
    _assert_requirement(isfinite(x), "Column :$colname contains non-finite frequency value: $x")
    _assert_requirement(x >= 0, "Column :$colname contains negative frequency value: $x")
    _assert_requirement(isinteger(x), "Column :$colname contains non-integer frequency value: $x")
    return Int(x)
end

function _normalize_pairs(pairs, labels::AbstractVector{<:AbstractString})
    if isnothing(pairs)
        return nothing
    end

    if isempty(pairs)
        return Tuple{Int,Int}[]
    end

    first_pair = first(pairs)

    if first_pair isa Tuple{Int,Int}
        return pairs
    elseif first_pair isa Tuple{String,String}
        label_to_idx = Dict(lbl => i for (i, lbl) in enumerate(labels))
        out = Tuple{Int,Int}[]
        for (a, b) in pairs
            @assert haskey(label_to_idx, a) "Unknown group label in pairs: $a"
            @assert haskey(label_to_idx, b) "Unknown group label in pairs: $b"
            i, j = label_to_idx[a], label_to_idx[b]
            i == j && error("Pair contains identical group: $a")
            push!(out, i < j ? (i, j) : (j, i))
        end
        unique!(out)
        return out
    elseif first_pair isa Tuple{Symbol,Symbol}
        spairs = [(String(a), String(b)) for (a, b) in pairs]
        return _normalize_pairs(spairs, labels)
    else
        error("Unsupported pairs type. Use Vector{Tuple{Int,Int}}, Vector{Tuple{String,String}}, or Vector{Tuple{Symbol,Symbol}}")
    end
end

_is_numeric(col) = (T = eltype(_get_clean_data(col)); nonmissingtype(T) <: Number && !(col isa AbstractCategoricalArray))
_is_ordered(col) = col isa AbstractCategoricalArray && isordered(col)
_is_categorical(col) = col isa AbstractCategoricalArray || eltype(_get_clean_data(col)) <: Union{AbstractString, Symbol, Bool}
_is_binary(col) = length(unique(_get_clean_data(col))) == 2

function _validate_columns(df::AbstractDataFrame, requirements::Pair{Symbol, Symbol}...)
    for (col, req) in requirements
        if req == :numeric
            _assert_requirement(_is_numeric(df[!, col]), "Column :$col must be numeric.")
        elseif req == :categorical
            _assert_requirement(_is_categorical(df[!, col]), "Column :$col must be categorical.")
        elseif req == :ordered
            _assert_requirement(_is_ordered(df[!, col]), "Column :$col must be ordered categorical.")
        elseif req == :binary
            _assert_requirement(_is_binary(df[!, col]), "Column :$col must be binary (exactly 2 levels).")
        end
    end
end

function _get_levels(col)
    col isa AbstractCategoricalArray ? levels(col) : sort(unique(_get_clean_data(col)))
end

function _convert_to_numeric(data)
    data isa AbstractCategoricalArray ? Float64.(levelcode.(data)) : Vector{Float64}(data)
end

function _extract_groups_with_labels(df::DataFrame, group_col::Symbol, data_col::Symbol; force_numeric_data=false)
    unique_labels = _get_levels(df[!, group_col])
    groups, labels_str = Vector{Vector{Float64}}(), String[]

    for lbl in unique_labels
        (isnothing(lbl) || ismissing(lbl)) && continue
        group_mask = isequal.(df[!, group_col], lbl)
        clean_data = _get_clean_data(df[group_mask, data_col])

        if !isempty(clean_data)
            push!(groups, force_numeric_data ? _convert_to_numeric(clean_data) : Vector{Float64}(clean_data))
            push!(labels_str, string(lbl))
        end
    end
    return groups, labels_str
end

function _extract_groups_with_labels(gd::GroupedDataFrame, data_col::Symbol; force_numeric_data=false)
    groups, labels_str = Vector{Vector{Float64}}(), String[]
    for (key, subdf) in pairs(gd)
        clean_data = _get_clean_data(subdf[!, data_col])
        if !isempty(clean_data)
            push!(groups, force_numeric_data ? _convert_to_numeric(clean_data) : Vector{Float64}(clean_data))
            push!(labels_str, _format_group_key(key))
        end
    end
    return groups, labels_str
end

function _extract_two_groups(args...; kwargs...)
    groups, labels = _extract_groups_with_labels(args...; kwargs...)
    _assert_requirement(length(groups) == 2, "Test requires exactly 2 groups. Found $(length(groups)): $labels")
    return groups[1], groups[2]
end

function _pivot_freq_table(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Union{Symbol, Nothing}=nothing)
    cols_to_clean = isnothing(freq_col) ? [row_col, col_col] : [row_col, col_col, freq_col]
    df_clean = _get_clean_df(df, cols_to_clean)

    r_levels_raw = _get_levels(df_clean[!, row_col])
    c_levels_raw = _get_levels(df_clean[!, col_col])

    r_labels = string.(r_levels_raw)
    c_labels = string.(c_levels_raw)

    r_map = Dict(v => i for (i, v) in enumerate(r_levels_raw))
    c_map = Dict(v => j for (j, v) in enumerate(c_levels_raw))

    tbl = zeros(Int, length(r_levels_raw), length(c_levels_raw))

    if isnothing(freq_col)
        for row in eachrow(df_clean)
            i = r_map[row[row_col]]
            j = c_map[row[col_col]]
            tbl[i, j] += 1
        end
    else
        for row in eachrow(df_clean)
            i = r_map[row[row_col]]
            j = c_map[row[col_col]]
            tbl[i, j] += Int(row[freq_col])
        end
    end

    return tbl, r_labels, c_labels
end

function _pivot_freq_table(gd::GroupedDataFrame, col_col::Symbol, freq_col::Union{Symbol, Nothing}=nothing)
    parent_df = parent(gd)
    c_levels_raw = _get_levels(parent_df[!, col_col])
    c_labels = string.(c_levels_raw)
    c_map = Dict(val => i for (i, val) in enumerate(c_levels_raw))
    r_labels = [_format_group_key(key) for key in keys(gd)]

    data_mat = zeros(Int, length(gd), length(c_levels_raw))

    for (i, subdf) in enumerate(gd)
        if isnothing(freq_col)
            clean_col = _get_clean_data(subdf[!, col_col])
            for val in clean_col
                if haskey(c_map, val)
                    data_mat[i, c_map[val]] += 1
                end
            end
        else
            sub_clean = _get_clean_df(subdf, [col_col, freq_col])
            for row in eachrow(sub_clean)
                val = row[col_col]
                if haskey(c_map, val)
                    data_mat[i, c_map[val]] += Int(row[freq_col])
                end
            end
        end
    end

    return data_mat, r_labels, c_labels
end