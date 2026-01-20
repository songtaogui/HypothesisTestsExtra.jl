using HypothesisTestsExtra
using HypothesisTests
using Test
using DataFrames
using Random
using Statistics
using StatsAPI

Random.seed!(1234)

@testset "HypothesisTestsExtra.jl Package Tests" begin

    # ==========================================================================
    # 1. Welch ANOVA Tests
    # ==========================================================================
    @testset "Welch ANOVA" begin

        g1 = randn(10)
        g2 = randn(10) .* 2 .+ 1
        g3 = randn(10) .* 0.5 .- 1
        
        # 1.1 Raw API
        t = WelchANOVATest(g1, g2, g3)
        @test t isa WelchANOVATest
        @test pvalue(t) isa Float64
        @test t.F > 0
        @test length(StatsAPI.nobs(t)) == 3
        @test length(StatsAPI.dof(t)) == 2 # (df1, df2)
        @test HypothesisTests.testname(t) == "Welch's ANOVA test (Unequal Variances)"
        @test HypothesisTests.population_param_of_interest(t)[1:2] == ("Means", "all equal")
        @test HypothesisTests.teststatisticname(t) == "F"
        @test HypothesisTests.teststatistic(t) == t.F
        t_exp_show = "Welch's ANOVA test (Unequal Variances)\n--------------------------------------\nPopulation details:\n    parameter of interest:   Means\n    value under h_0:         \"all equal\"\n    point estimate:          NaN\n\nTest summary:\n    outcome with 95% confidence: reject h_0\n    two-sided p-value:           0.0017155113460403859\n\nDetails:\n    number of observations: [10, 10, 10]\n    F statistic:            10.5193415505797\n    degrees of freedom:     (2.0, 13.665610261988927)\n"
        @test sprint(show, t) == t_exp_show

        # 1.2 DataFrame
        df = DataFrame(
            group = vcat(fill("A", 10), fill("B", 10), fill("C", 10)),
            val = vcat(g1, g2, g3)
        )
        t_df = WelchANOVATest(df, :group, :val)
        @test pvalue(t_df) ≈ pvalue(t)
    end

    # ==========================================================================
    # 2. Fisher's Exact Test (RxC Extension)
    # ==========================================================================
    @testset "Fisher RxC & MC" begin
        # 2.1 2x2 (should fallback to FisherExactTest)
        m_2x2 = [10 5; 2 15]
        ft_2x2 = FisherExactTestRxC(m_2x2)
        @test ft_2x2 isa HypothesisTests.FisherExactTest
        ftr = FisherExactTest(m_2x2)
        @test ftr isa HypothesisTests.FisherExactTest
        
        # 2.2 RxC (should use FisherExactTestMC)
        m_rxc = [5 10 2; 3 15 7; 12 4 10]
        ft_mc = FisherExactTestRxC(m_rxc)
        @test ft_mc isa FisherExactTestMC
        @test HypothesisTests.testname(ft_mc) == "Fisher's Exact Test for RxC Tables (Monte Carlo)"
        @test HypothesisTests.population_param_of_interest(ft_mc)[1:2] == ("P-value", 0.0)
        @test HypothesisTests.default_tail(ft_mc) == :right
        @test sprint(HypothesisTests.show_params,ft_mc) == "contingency table (size (3, 3)):\n 5  10   2\n 3  15   7\n12   4  10\n"

        # StatsAPI
        pval = pvalue(ft_mc; n_sim=5000)
        ci = confint(ft_mc; n_sim=5000)
        @test 0.0 <= pval <= 1.0
        @test ci[1] <= ci[2]

        # 2.3 DataFrame API (Raw Data)
        df_cat = DataFrame(a=["A","A","B","B"], b=["X","Y","X","Y"])
        ft_df = FisherExactTestRxC(df_cat, :a, :b)
        @test pvalue(ft_df) isa Float64

        # 2.4 DataFrame API (Frequency Data)
        df_freq = DataFrame(a=["A","A","B","B"], b=["X","Y","X","Y"], count=[10, 5, 2, 8])
        ft_freq = FisherExactTestRxC(df_freq, :a, :b, :count)
        @test ft_freq isa HypothesisTests.FisherExactTest # 2x2 case
    end

    # ==========================================================================
    # 3. Parametric Post-Hoc Tests
    # ==========================================================================
    @testset "PostHoc Parametric" begin
        g1 = randn(20)
        g2 = randn(20) .+ 2
        g3 = randn(20) .- 2
        groups = [g1, g2, g3]

        # 3.1 different methods (Dispatch check)
        methods = [:tukey, :bonferroni, :lsd, :scheffe, :sidak, :tamhane, :lsd, :duncan]
        for m in methods
            res = PostHocTest(groups; method=m)
            @test res isa PostHocTestResult
            @test res.method == m
            @test length(res.comparisons) == 3 # 3 pairs
        end

        # 3.2 CLD (Compact Letter Display)
        res_cld = PostHocTest(groups; method=:tukey, cld=true)
        @test !isempty(res_cld.cld_letters)

        # test boardcast method
        pha = PostHocTest(groups...) 
        phb = PostHocTest(groups)
        @test pha.comparisons == phb.comparisons

        # 3.3 DataFrame API
        df = DataFrame(
            grp = vcat(fill("G1", 20), fill("G2", 20), fill("G3", 20)),
            val = vcat(g1, g2, g3)
        )
        res_df = PostHocTest(df, :grp, :val; method=:tukey)
        @test res_df isa PostHocTestResult
        top66="\n------------------------------\nPost-hoc Test: :tukey (alpha=0.05)"
        @test sprint(show, res_df)[1:66] == top66

        # 3.4 Results to DataFrame
        df_res = DataFrame(res_df)
        @test nrow(df_res) == 3
        @test "P-value" in names(df_res)
        
        df_cld = GroupTestToDataframe(res_df)
        @test nrow(df_cld) == 3 # 3 groups

        ph = PostHocTest(1:5, 1:5; cld = true)
        tt = PostHocTestResult(ph.method, ph.comparisons, ph.alpha, ph.use_cld, ph.cld_letters, Dict{Int64, String}())
        df_tt = GroupTestToDataframe(tt)
        @test nrow(df_tt) == 2
    end

    # ==========================================================================
    # 4. Non-Parametric Post-Hoc Tests
    # ==========================================================================
    @testset "PostHoc Non-Parametric" begin
        g1 = rand(10)
        g2 = rand(10) .+ 0.5
        g3 = rand(10)
        
        # 4.1 Methods
        res_dunn = PostHocNonPar(g1, g2, g3; method=:dunn_bonferroni)
        @test res_dunn.method == :dunn_bonferroni
        
        res_nemenyi = PostHocNonPar([g1, g2, g3]; method=:nemenyi)
        @test res_nemenyi.method == :nemenyi

        res_nemenyi = PostHocNonPar([g1, g2, g3]; method=:dunn)
        @test res_nemenyi.method == :dunn

        res_nemenyi = PostHocNonPar([g1, g2, g3]; method=:dunn_sidak, cld=true)
        @test res_nemenyi.method == :dunn_sidak

        # 4.2 DataFrame API
        df = DataFrame(
            grp = vcat(fill("A", 10), fill("B", 10), fill("C", 10)),
            val = vcat(g1, g2, g3)
        )
        res_df = PostHocNonPar(df, :grp, :val)
        @test res_df isa PostHocTestResult
    end

    # ==========================================================================
    # 5. Contingency Post-Hoc (Row & Cell)
    # ==========================================================================
    @testset "PostHoc Contingency" begin
        tbl = [20 10 5; 10 20 5; 5 5 20]
        
        # 5.1 Cell-Level
        # ASR
        asr_cell = PostHocContingencyCell(tbl; method=:asr, adjustment=:bonferroni)
        @test asr_cell isa ContingencyCellTestResult
        @test sprint(show, asr_cell)[1:70] == "\n========================================\nPost-hoc Cell Analysis: :asr"

        # fisher_1vsall
        fisher_cell = PostHocContingencyCell(tbl; method=:fisher_1vsall, adjustment=:bonferroni)
        @test fisher_cell isa ContingencyCellTestResult
        # Res to DF
        res_cell = asr_cell
        df_long = DataFrame(res_cell)
        @test nrow(df_long) == 9 # 3x3 cells
        df_mat = CellTestToDataframe(res_cell)
        @test nrow(df_mat) == 3

        # 5.2 Row-Level (Pairwise ChiSq/Fisher)
        res_row = PostHocContingencyRow(tbl; method=:chisq, adjustment=:bh)
        @test res_row isa PostHocTestResult
        @test length(res_row.comparisons) == 3 # 3 rows, 3 pairs
        # Fisher && CLD
        fisher_row = PostHocContingencyRow(tbl; method=:fisher, adjustment=:bh, cld=true)
        @test fisher_row isa PostHocTestResult
        # 5.3 DataFrame API (Raw Data)
        df_raw = DataFrame(
            R = ["R1", "R1", "R2", "R2", "R3", "R3"],
            C = ["C1", "C2", "C1", "C2", "C1", "C2"]
        )
        @test PostHocContingencyCell(df_raw, :R, :C) isa ContingencyCellTestResult
        @test PostHocContingencyRow(df_raw, :R, :C) isa PostHocTestResult

        # 5.4 DataFrame API (Frequency Data)
        df_freq = DataFrame(
            R = ["R1", "R1", "R2", "R2"],
            C = ["C1", "C2", "C1", "C2"],
            N = [10, 5, 5, 10]
        )
        @test PostHocContingencyCell(df_freq, :R, :C, :N) isa ContingencyCellTestResult
        @test PostHocContingencyRow(df_freq, :R, :C, :N) isa PostHocTestResult
    end

    # ==========================================================================
    # 6. DataFrame Extension Wrappers (General HypothesisTests)
    # ==========================================================================
    @testset "DataFrame Extensions (General)" begin
        # For T-test, MWU etc.
        df_2 = DataFrame(
            g = vcat(fill("A", 10), fill("B", 10)),
            x = randn(20)
        )
        # For ANOVA, KW, Levene etc.
        df_3 = DataFrame(
            g = vcat(fill("A", 10), fill("B", 10), fill("C", 10)),
            x = randn(30)
        )
        # cat table
        df_cat = DataFrame(r=["A","A","B","B"], c=["X","Y","X","Y"])
        df_freq = DataFrame(r=["A","A","B","B"], c=["X","Y","X","Y"], n=[10,5,2,8])

        # 6.1 K-Sample Tests
        @test OneWayANOVATest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
        @test KruskalWallisTest(df_3, :g, :x) isa KruskalWallisTest
        
        # 6.2 Variance Tests
        @test LeveneTest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
        @test BrownForsytheTest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
        @test FlignerKilleenTest(df_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
        @test VarianceFTest(df_2, :g, :x) isa VarianceFTest

        # 6.3 Two-Sample Tests
        @test EqualVarianceTTest(df_2, :g, :x) isa EqualVarianceTTest
        @test UnequalVarianceTTest(df_2, :g, :x) isa UnequalVarianceTTest
        @test MannWhitneyUTest(df_2, :g, :x) isa ExactMannWhitneyUTest
        @test ApproximateTwoSampleKSTest(df_2, :g, :x) isa ApproximateTwoSampleKSTest

        # 6.4 Categorical Tests
        @test ChisqTest(df_cat, :r, :c) isa PowerDivergenceTest
        @test ChisqTest(df_freq, :r, :c, :n) isa PowerDivergenceTest
        @test FisherExactTest(df_cat, :r, :c) isa FisherExactTest
        @test FisherExactTest(df_freq, :r, :c, :n) isa FisherExactTest
        @test PowerDivergenceTest(df_cat, :r, :c) isa PowerDivergenceTest
        @test PowerDivergenceTest(df_freq, :r, :c, :n) isa PowerDivergenceTest
    end
    # ==========================================================================
    # 7. Misc functions
    # ==========================================================================
    randP = randn(5)
    @test HypothesisTestsExtra.adjust_pvalues(randP, :none) == randP
    @test_throws ErrorException HypothesisTestsExtra.adjust_pvalues(randP, :abc)

end
