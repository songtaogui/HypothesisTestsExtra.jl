# test/test_dataframe.jl

# ==============================================================================
# 1. DataFrame Extensions Tests
# ==============================================================================
@testset "DataFrame Extensions" begin

    # --- Welch ANOVA ---
    @testset "Welch ANOVA - DF" begin
        g1 = randn(10)
        g2 = randn(10) .* 2 .+ 1
        g3 = randn(10) .* 0.5 .- 1
        
        df = DataFrame(
            group = categorical(vcat(fill("A", 10), fill("B", 10), fill("C", 10))),
            val = vcat(g1, g2, g3)
        )
        t_df = WelchANOVATest(df, :group, :val)
        @test t_df isa WelchANOVATest
    end

    # --- Fisher RxC ---
    @testset "Fisher RxC - DF" begin
        # Raw Data: Requires categorical columns
        df_cat = DataFrame(
            a = categorical(["A","A","B","B"]), 
            b = categorical(["X","Y","X","Y"])
        )
        ft_df = FisherExactTestRxC(df_cat, :a, :b)
        @test pvalue(ft_df) isa Float64

        # Frequency Data
        df_freq = DataFrame(
            a = categorical(["A","A","B","B"]), 
            b = categorical(["X","Y","X","Y"]), 
            count = [10, 5, 2, 8]
        )
        ft_freq = FisherExactTestRxC(df_freq, :a, :b, :count)
        # Note: Depending on implementation, RxC might return a specific test type
        @test pvalue(ft_freq) >= 0
    end

    # --- Post-Hoc Tests ---
    @testset "PostHoc Tests - DF" begin
        df = DataFrame(
            grp = categorical(vcat(fill("G1", 20), fill("G2", 20), fill("G3", 20))),
            val = randn(60)
        )
        
        # Parametric: Tukey
        res_df = PostHocPar(df, :grp, :val; method=:tukey)
        @test res_df isa PostHocTestResult
        
        # To DataFrame conversion (assuming these helpers exist)
        df_res = DataFrame(res_df)
        @test nrow(df_res) == 3
        @test "P-value" in names(df_res)
        
        # Non-Parametric: Dunn
        res_np_df = PostHocNonPar(df, :grp, :val)
        @test res_np_df isa PostHocTestResult
    end

    # --- Contingency Post-Hoc ---
    @testset "Contingency PostHoc - DF" begin
        # Raw Data
        df_raw = DataFrame(
            R = categorical(["R1", "R1", "R2", "R2", "R3", "R3"]),
            C = categorical(["C1", "C2", "C1", "C2", "C1", "C2"])
        )
        @test PostHocContingencyCell(df_raw, :R, :C) isa ContingencyCellTestResult
        @test PostHocContingencyRow(df_raw, :R, :C) isa PostHocTestResult

        # Frequency Data
        df_freq = DataFrame(
            R = categorical(["R1", "R1", "R2", "R2"]),
            C = categorical(["C1", "C2", "C1", "C2"]),
            N = [10, 5, 5, 10]
        )
        @test PostHocContingencyCell(df_freq, :R, :C, :N) isa ContingencyCellTestResult
        @test PostHocContingencyRow(df_freq, :R, :C, :N) isa PostHocTestResult
    end

    # --- General Wrappers ---
    @testset "General Wrappers - DF" begin
        df_2 = DataFrame(
            g = categorical(vcat(fill("A", 10), fill("B", 10))),
            x = randn(20)
        )
        df_3 = DataFrame(
            g = categorical(vcat(fill("A", 10), fill("B", 10), fill("C", 10))),
            x = randn(30)
        )
        df_cat = DataFrame(
            r = categorical(["A","A","B","B"]), 
            c = categorical(["X","Y","X","Y"])
        )
        df_freq = DataFrame(
            r = categorical(["A","A","B","B"]), 
            c = categorical(["X","Y","X","Y"]), 
            n = [10, 5, 2, 8]
        )

        # K-Sample
        @test OneWayANOVATest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
        @test KruskalWallisTest(df_3, :g, :x) isa KruskalWallisTest
        
        # Variance
        @test LeveneTest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
        @test BrownForsytheTest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
        @test FlignerKilleenTest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
        @test VarianceFTest(df_2, :g, :x) isa VarianceFTest

        # Two-Sample
        @test EqualVarianceTTest(df_2, :g, :x) isa EqualVarianceTTest
        @test UnequalVarianceTTest(df_2, :g, :x) isa UnequalVarianceTTest
        @test MannWhitneyUTest(df_2, :g, :x) isa ExactMannWhitneyUTest
        @test ApproximateTwoSampleKSTest(df_2, :g, :x) isa ApproximateTwoSampleKSTest

        # Categorical
        @test ChisqTest(df_cat, :r, :c) isa PowerDivergenceTest
        @test ChisqTest(df_freq, :r, :c, :n) isa PowerDivergenceTest
        @test FisherExactTest(df_cat, :r, :c) isa FisherExactTest
        @test FisherExactTest(df_freq, :r, :c, :n) isa FisherExactTest
    end
end
