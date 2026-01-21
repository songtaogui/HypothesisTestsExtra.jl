using HypothesisTestsExtra
using HypothesisTests
using Test
using DataFrames
using Random
using Statistics
using StatsAPI

Random.seed!(1234)

@testset "HypothesisTestsExtra.jl Package Tests" begin
    # Include tests for raw arrays and core logic
    include("test_core_api.jl")

    # Include tests for DataFrame extensions
    include("test_dataframe.jl")

    # Include tests for GroupedDataFrame extensions
    include("test_groupeddataframe.jl")
end
