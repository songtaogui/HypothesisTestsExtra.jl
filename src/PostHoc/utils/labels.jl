# src/PostHoc/utils/labels.jl


"""
    _get_auto_labels(table::AbstractMatrix, dim::Int, manual_labels::AbstractVector{<:AbstractString}, prefix::String)

Internal helper function to resolve row or column labels.

Resolution Priority:
1. User-provided `manual_labels`.
2. Automatic extraction via `names(table, dim)` (supports `NamedArrays.jl`).
3. Default generated labels (e.g., "R1", "R2").

# Arguments
- `table`: The contingency table.
- `dim`: Dimension to extract (1 for rows, 2 for columns).
- `manual_labels`: Vector of strings provided by the user.
- `prefix`: Prefix for default label generation (e.g., "Row").
"""
function _get_auto_labels(table::AbstractMatrix, dim::Int, manual_labels::AbstractVector{<:AbstractString}, prefix::String)
    # 1. Use manual labels if provided and valid
    if !isempty(manual_labels)
        return manual_labels
    end

    # 2. Try to extract names (Support for NamedArrays.jl and similar structures)
    try
        extracted = names(table, dim)
        if length(extracted) == size(table, dim)
            return string.(extracted)
        end
    catch
        # Fallthrough on MethodError (not a NamedArray) or other indexing issues
    end

    # 3. Default fallback: Generate generic labels
    return ["$prefix$i" for i in 1:size(table, dim)]
end
