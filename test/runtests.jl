using HypothesisTestsExtra
using HypothesisTests
using Test
using DataFrames
using Random
using Statistics
using StatsAPI

Random.seed!(1234)

@testset "HypothesisTestsExtra.jl Package Tests" begin
    include("test_core_api.jl")
    include("test_dataframe.jl")
    include("test_groupeddataframe.jl")
end
