# test/test_groupeddataframe.jl

# ==============================================================================
# 2. GroupedDataFrame Extensions Tests
# ==============================================================================
@testset "GroupedDataFrame Extensions" begin

    # --- Setup Data ---
    df_3 = DataFrame(g = categorical(vcat(fill("A", 10), fill("B", 10), fill("C", 10))), x = randn(30))
    gd_3 = groupby(df_3, :g)

    df_2 = DataFrame(g = categorical(vcat(fill("A", 10), fill("B", 10))), x = randn(20))
    gd_2 = groupby(df_2, :g)

    df_cat = DataFrame(
        row = categorical(vcat(fill("R1", 20), fill("R2", 20))),
        col = categorical(rand(["C1", "C2", "C3"], 40)) 
    )
    gd_cat = groupby(df_cat, :row)

    df_2x2 = DataFrame(
        row = categorical(vcat(fill("G1", 10), fill("G2", 10))),
        col = categorical(vcat(rand(["Yes", "No"], 10), rand(["Yes", "No"], 10)))
    )
    gd_2x2 = groupby(df_2x2, :row)

    # --- Post-Hoc Tests (Numerical) ---
    @testset "PostHoc Tests - GD" begin
        # Parametric: Tukey
        # Revised: Removed :g, dispatch uses GDF keys
        res_gd = PostHocPar(gd_3, :x; method=:tukey)
        @test res_gd isa PostHocTestResult
        @test length(res_gd.comparisons) == 3

        # Non-Parametric: Dunn
        res_np_gd = PostHocNonPar(gd_3, :x; method=:dunn)
        @test res_np_gd isa PostHocTestResult
    end

    # --- Contingency Post-Hoc (Categorical) ---
    @testset "Contingency PostHoc - GD" begin
        # Row-Level Analysis
        res_row = PostHocContingencyRow(gd_cat, :col; method=:chisq)
        @test res_row isa PostHocTestResult
        
        # Cell-Level Analysis (ASR)
        res_cell = PostHocContingencyCell(gd_cat, :col; method=:asr)
        @test res_cell isa ContingencyCellTestResult
    end

    # --- Standard Categorical Tests ---
    @testset "Categorical Tests - GD" begin
        @test ChisqTest(gd_cat, :col) isa PowerDivergenceTest
        @test FisherExactTest(gd_2x2, :col) isa FisherExactTest
        @test FisherExactTestRxC(gd_cat, :col) isa FisherExactTestMC
        @test PowerDivergenceTest(gd_cat, :col) isa PowerDivergenceTest
    end

    # --- K-Sample & Variance Tests ---
    @testset "K-Sample & Variance - GD" begin
        @test OneWayANOVATest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest
        @test WelchANOVATest(gd_3, :x) isa WelchANOVATest
        @test KruskalWallisTest(gd_3, :x) isa KruskalWallisTest

        @test LeveneTest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest
        @test BrownForsytheTest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest
        @test FlignerKilleenTest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest
    end

    # --- Two-Sample Tests ---
    @testset "Two-Sample - GD" begin
        @test EqualVarianceTTest(gd_2, :x) isa EqualVarianceTTest
        @test UnequalVarianceTTest(gd_2, :x) isa UnequalVarianceTTest
        @test VarianceFTest(gd_2, :x) isa VarianceFTest
        @test MannWhitneyUTest(gd_2, :x) isa ExactMannWhitneyUTest{Float64}
        @test ApproximateTwoSampleKSTest(gd_2, :x) isa ApproximateTwoSampleKSTest

        # Expect error if GD has more than 2 groups
        @test_throws ArgumentError EqualVarianceTTest(gd_3, :x)
    end
end
