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

    # --- Trend and Association Tests ---
    @testset "Trend & Association - DF" begin
        # Jonckheere-Terpstra
        df_jt = DataFrame(
            grp = categorical(vcat(fill("L1", 10), fill("L2", 10), fill("L3", 10)); ordered=true),
            val = vcat(randn(10) .- 1, randn(10), randn(10) .+ 1)
        )
        @test JonckheereTerpstraTest(df_jt, :grp, :val) isa JonckheereTerpstraTest

        # Cochran-Armitage (raw)
        df_ca = DataFrame(
            dose = categorical(vcat(fill("Low", 20), fill("Mid", 20), fill("High", 20)); ordered=true),
            resp = categorical(vcat(rand(["No", "Yes"], 20), rand(["No", "Yes"], 20), rand(["No", "Yes"], 20)))
        )
        @test CochranArmitageTest(df_ca, :dose, :resp) isa CochranArmitageTest

        # Cochran-Armitage (freq)
        df_ca_freq = DataFrame(
            dose = categorical(repeat(["Low", "Mid", "High"], inner=2); ordered=true),
            resp = categorical(repeat(["No", "Yes"], 3)),
            n = [8, 12, 10, 10, 6, 14]
        )
        @test CochranArmitageTest(df_ca_freq, :dose, :resp, :n) isa CochranArmitageTest

        # Linear-by-Linear (raw)
        df_lbl = DataFrame(
            x = categorical(vcat(fill("L1", 20), fill("L2", 20), fill("L3", 20)); ordered=true),
            y = categorical(rand(["S", "M", "L"], 60); ordered=true)
        )
        @test LinearByLinearTest(df_lbl, :x, :y) isa LinearByLinearTest

        # Linear-by-Linear (freq)
        df_lbl_freq = DataFrame(
            x = categorical(repeat(["L1", "L2", "L3"], inner=3); ordered=true),
            y = categorical(repeat(["S", "M", "L"], 3); ordered=true),
            n = [5, 8, 7, 6, 9, 5, 4, 7, 10]
        )
        @test LinearByLinearTest(df_lbl_freq, :x, :y, :n) isa LinearByLinearTest
    end

    # --- One-Sample Tests ---
    @testset "One-Sample - DF" begin
        df_one = DataFrame(x = randn(30))
        @test OneSampleTTest(df_one, :x) isa OneSampleTTest
        @test OneSampleZTest(df_one, :x) isa OneSampleZTest
        @test SignTest(df_one, :x) isa SignTest
        @test SignedRankTest(df_one, :x) isa ExactSignedRankTest

        df_bin_bool = DataFrame(x = rand([true, false], 40))
        df_bin_num = DataFrame(x = rand(0:1, 40))
        df_bin_str = DataFrame(x = rand(["a", "b"], 40))
        @test BinomialTest(df_bin_bool, :x) isa BinomialTest
        @test BinomialTest(df_bin_num, :x) isa BinomialTest
        @test BinomialTest(df_bin_str, :x) isa BinomialTest
    end

    # --- Paired/Binary-group Wrappers ---
    @testset "Paired Wrappers - DF" begin
        df_pair = DataFrame(
            g = categorical(vcat(fill("A", 15), fill("B", 15))),
            x = randn(30)
        )
        @test SignTest(df_pair, :g, :x) isa SignTest
        @test SignedRankTest(df_pair, :g, :x) isa ExactSignedRankTest
    end

end
