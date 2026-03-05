#FILEPATH: test/ext_df/test_gdf_twosample.jl

@testset "GroupedDataFrame extension: two-sample wrappers" begin
    df_2 = DataFrame(g = vcat(fill("A", 12), fill("B", 12)), x = randn(24))
    gd_2 = groupby(df_2, :g)

    @test EqualVarianceTTest(gd_2, :x) isa EqualVarianceTTest
    @test UnequalVarianceTTest(gd_2, :x) isa UnequalVarianceTTest
    @test VarianceFTest(gd_2, :x) isa VarianceFTest
    @test MannWhitneyUTest(gd_2, :x) isa ExactMannWhitneyUTest{Float64}
    @test ApproximateTwoSampleKSTest(gd_2, :x) isa ApproximateTwoSampleKSTest

    df_3 = DataFrame(g = vcat(fill("A", 8), fill("B", 8), fill("C", 8)), x = randn(24))
    gd_3 = groupby(df_3, :g)
    @test_throws ArgumentError EqualVarianceTTest(gd_3, :x)
end
