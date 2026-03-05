#FILEPATH: test/ext_df/test_gdf_multisample.jl

@testset "GroupedDataFrame extension: multi-sample wrappers and posthoc" begin
    df_3 = DataFrame(g = vcat(fill("A", 10), fill("B", 10), fill("C", 10)), x = randn(30))
    gd_3 = groupby(df_3, :g)

    @test OneWayANOVATest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest
    @test WelchANOVATest(gd_3, :x) isa WelchANOVATest
    @test KruskalWallisTest(gd_3, :x) isa KruskalWallisTest
    @test LeveneTest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest
    @test BrownForsytheTest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest
    @test FlignerKilleenTest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest

    @test PostHocPar(gd_3, :x; method=:tukey) isa PostHocTestResult
    @test PostHocNonPar(gd_3, :x; method=:dunn) isa PostHocTestResult
end
