# test/runtests.jl

using HypothesisTestsExtra
using HypothesisTests
using Test
using DataFrames
using Random
using Statistics
using StatsAPI
using CategoricalArrays
using NamedArrays
using Aqua

Random.seed!(1234)

@testset "Aqua.jl" begin
    Aqua.test_all(HypothesisTestsExtra; piracies = false)
end

@testset "HypothesisTestsExtra.jl Package Tests" begin
    include("test_api.jl")
    include("test_df.jl")
    include("test_gdf.jl")
    include("test_dirty.jl")
    include("test_typesafety.jl")
end
