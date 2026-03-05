#FILEPATH: test/ext_df/test_df_multisample.jl

@testset "DataFrame extension: multi-sample wrappers and posthoc" begin
    df_3 = DataFrame(
        g = vcat(fill("A", 15), fill("B", 15), fill("C", 15)),
        x = randn(45)
    )

    @test OneWayANOVATest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
    @test WelchANOVATest(df_3, :g, :x) isa WelchANOVATest
    @test KruskalWallisTest(df_3, :g, :x) isa KruskalWallisTest
    @test LeveneTest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
    @test BrownForsytheTest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
    @test FlignerKilleenTest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest

    @test PostHocPar(df_3, :g, :x; method=:tukey) isa PostHocTestResult
    @test PostHocNonPar(df_3, :g, :x; method=:dunn) isa PostHocTestResult
end
