# src/Dispatch/helpers.jl

# ==============================================================================
#  Helper Functions: Validation, Cleaning, and Extraction
# ==============================================================================

"""
    _is_valid_value(x)
Check if a value is not missing, nothing, or NaN.
"""
@inline _is_valid_value(x) = !ismissing(x) && !isnothing(x) && (!(x isa Number) || !isnan(x))

"""
    _get_clean_data(col)
Returns a collection of values filtering out missing, nothing, and NaN.
"""
_get_clean_data(col) = [x for x in col if _is_valid_value(x)]

"""
    _get_clean_df(df::AbstractDataFrame, cols::Vector{Symbol})
Returns a copy of the DataFrame with rows removed where any of the specified 
columns contain invalid values (missing, nothing, or NaN).
"""
function _get_clean_df(df::AbstractDataFrame, cols::Vector{Symbol})
    return filter(row -> all(_is_valid_value(row[c]) for c in cols), df[:, cols])
end

# --- Type Checkers ---

_is_numeric(col) = (T = eltype(_get_clean_data(col)); nonmissingtype(T) <: Number && !(col isa AbstractCategoricalArray))
_is_ordered(col) = col isa AbstractCategoricalArray && isordered(col)
_is_categorical(col) = col isa AbstractCategoricalArray || eltype(_get_clean_data(col)) <: Union{AbstractString, Symbol, Bool}
_is_binary(col) = length(unique(_get_clean_data(col))) == 2

"""
    _validate_columns(df::AbstractDataFrame, requirements::Pair{Symbol, Symbol}...)
Validates multiple columns against specific types. 
Types: :numeric, :categorical, :ordered, :binary.
"""
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

_assert_requirement(cond::Bool, msg::String) = cond || throw(ArgumentError(msg))

# --- Extraction Helpers ---

function _get_levels(col)
    col isa AbstractCategoricalArray ? levels(col) : sort(unique(_get_clean_data(col)))
end

function _convert_to_numeric(data)
    data isa AbstractCategoricalArray ? Float64.(levelcode.(data)) : Vector{Float64}(data)
end

function _format_group_key(key)
    vals = values(key)
    return length(vals) == 1 ? string(vals[1]) : join(string.(vals), " | ")
end

"""
    _extract_groups_with_labels(df::DataFrame, group_col, data_col; force_numeric_data=false)
Unified group extractor for DataFrames.
"""
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

# --- Table Helpers ---

function _pivot_freq_table(df::DataFrame, row_col::Symbol, col_col::Symbol, freq_col::Union{Symbol, Nothing})
    cols_to_clean = isnothing(freq_col) ? [row_col, col_col] : [row_col, col_col, freq_col]
    df_clean = _get_clean_df(df, cols_to_clean)
    
    if isnothing(freq_col)
        # Raw data: use freqtable directly
        tbl = freqtable(df_clean, row_col, col_col)
    else
        # Weighted/Frequency data: unstack
        wide_df = unstack(df_clean, row_col, col_col, freq_col, fill=0)
        r_labels = string.(wide_df[!, 1])
        c_labels = names(wide_df)[2:end]
        data_mat = Matrix{Int}(wide_df[:, 2:end])
        return NamedArray(data_mat, (r_labels, c_labels), (string(row_col), string(col_col)))
    end
    return tbl
end

function _pivot_freq_table(gd::GroupedDataFrame, col_col::Symbol, freq_col::Union{Symbol, Nothing}=nothing)
    parent_df = parent(gd)
    c_labels_raw = _get_levels(parent_df[!, col_col])
    c_labels = string.(c_labels_raw)
    c_map = Dict(val => i for (i, val) in enumerate(c_labels_raw))
    r_labels = [_format_group_key(key) for key in keys(gd)]

    if isnothing(freq_col)
         T = Int
    else
         T = nonmissingtype(eltype(parent_df[!, freq_col]))
         @assert T <: Int "The freq values should be Int for col : $(freq_col)"
    end

    data_mat = zeros(T, length(gd), length(c_labels))

    for (i, subdf) in enumerate(gd)
        if isnothing(freq_col)
            clean_col = _get_clean_data(subdf[!, col_col])
            for val in clean_col
                if haskey(c_map, val)
                    data_mat[i, c_map[val]] += one(T)
                end
            end
        else
            sub_clean = _get_clean_df(subdf, [col_col, freq_col])
            for row in eachrow(sub_clean)
                val = row[col_col]
                if haskey(c_map, val)
                    data_mat[i, c_map[val]] += convert(T, row[freq_col])
                end
            end
        end
    end

    return NamedArray(data_mat, (r_labels, c_labels), ("Group", string(col_col)))
end


