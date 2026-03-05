# test/runtests.jl

using HypothesisTestsExtra
using Test
using Random
using Statistics
using StatsAPI
using HypothesisTests
using Aqua
using DataFrames
using CategoricalArrays

Random.seed!(1234)

@testset "HypothesisTestsExtra.jl Package Tests" begin
    # Optional package QA
    Aqua.test_all(HypothesisTestsExtra; ambiguities=false)

    include("common/test_formatters_and_helpers.jl")
    include("core/test_api_raw.jl")

    # DataFrames-only extension behavior
    include("ext_df/test_df_onesample.jl")
    include("ext_df/test_df_twosample.jl")
    include("ext_df/test_df_multisample.jl")
    include("ext_df/test_df_contingency.jl")
    include("ext_df/test_df_dirty.jl")
    include("ext_df/test_df_typesafety.jl")
    include("ext_df/test_gdf_twosample.jl")
    include("ext_df/test_gdf_multisample.jl")
    include("ext_df/test_gdf_contingency.jl")

    # CategoricalArrays-dependent extension behavior
    include("ext_categorical/test_df_trends.jl")
    include("ext_categorical/test_gdf_trends.jl")
    include("ext_categorical/test_categorical_typesafety.jl")
end
