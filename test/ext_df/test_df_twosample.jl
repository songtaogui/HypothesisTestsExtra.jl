#FILEPATH: test/ext_df/test_df_twosample.jl

@testset "DataFrame extension: two-sample wrappers" begin
    df_2 = DataFrame(
        g = vcat(fill("A", 20), fill("B", 20)),
        x = randn(40)
    )

    @test EqualVarianceTTest(df_2, :g, :x) isa EqualVarianceTTest
    @test UnequalVarianceTTest(df_2, :g, :x) isa UnequalVarianceTTest
    @test VarianceFTest(df_2, :g, :x) isa VarianceFTest
    @test MannWhitneyUTest(df_2, :g, :x) isa ExactMannWhitneyUTest
    @test ApproximateTwoSampleKSTest(df_2, :g, :x) isa ApproximateTwoSampleKSTest

    @test SignTest(df_2, :g, :x) isa SignTest
    @test SignedRankTest(df_2, :g, :x) isa ExactSignedRankTest
end
