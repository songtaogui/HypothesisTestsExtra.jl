@testset "Core API (Raw Arrays & Matrices)" begin

    # ==========================================================================
    # Welch ANOVA (Raw)
    # ==========================================================================
    @testset "Welch ANOVA - Raw" begin
        g1 = randn(10)
        g2 = randn(10) .* 2 .+ 1
        g3 = randn(10) .* 0.5 .- 1
        
        t = WelchANOVATest(g1, g2, g3)
        @test t isa WelchANOVATest
        @test pvalue(t) isa Float64
        @test t.F > 0
        @test length(StatsAPI.nobs(t)) == 3
        @test length(StatsAPI.dof(t)) == 2
        @test HypothesisTests.testname(t) == "Welch's ANOVA test (Unequal Variances)"
        @test HypothesisTests.teststatisticname(t) == "F"
        
        # Check show output
        t_exp_show = "Welch's ANOVA test (Unequal Variances)\n--------------------------------------\nPopulation details:\n    parameter of interest:   Means\n    value under h_0:         \"all equal\"\n    point estimate:          NaN\n\nTest summary:\n    outcome with 95% confidence: reject h_0\n    two-sided p-value:           0.0017155113460403859\n\nDetails:\n    number of observations: [10, 10, 10]\n    F statistic:            10.5193415505797\n    degrees of freedom:     (2.0, 13.665610261988927)\n"
        @test sprint(show, t) == t_exp_show
    end

    # ==========================================================================
    # Fisher's Exact Test (RxC & MC)
    # ==========================================================================
    @testset "Fisher RxC & MC - Raw" begin
        # 2x2 fallback
        m_2x2 = [10 5; 2 15]
        ft_2x2 = FisherExactTestRxC(m_2x2)
        @test ft_2x2 isa HypothesisTests.FisherExactTest
        ftr = FisherExactTest(m_2x2)
        @test ftr isa HypothesisTests.FisherExactTest
        
        # RxC MC
        m_rxc = [5 10 2; 3 15 7; 12 4 10]
        ft_mc = FisherExactTestRxC(m_rxc)
        @test ft_mc isa FisherExactTestMC
        @test HypothesisTests.testname(ft_mc) == "Fisher's Exact Test for RxC Tables (Monte Carlo)"
        
        # StatsAPI methods
        pval = pvalue(ft_mc; n_sim=5000)
        ci = confint(ft_mc; n_sim=5000)
        @test 0.0 <= pval <= 1.0
        @test ci[1] <= ci[2]
    end

    # ==========================================================================
    # Parametric Post-Hoc Tests
    # ==========================================================================
    @testset "PostHoc Parametric - Raw" begin
        g1 = randn(20)
        g2 = randn(20) .+ 2
        g3 = randn(20) .- 2
        groups = [g1, g2, g3]

        # Dispatch check
        methods = [:tukey, :bonferroni, :lsd, :scheffe, :sidak, :tamhane, :lsd, :duncan]
        for m in methods
            res = PostHocTest(groups; method=m)
            @test res isa PostHocTestResult
            @test res.method == m
            @test length(res.comparisons) == 3
        end

        # CLD
        res_cld = PostHocTest(groups; method=:tukey, cld=true)
        @test !isempty(res_cld.cld_letters)

        # Broadcast check
        pha = PostHocTest(groups...) 
        phb = PostHocTest(groups)
        @test pha.comparisons == phb.comparisons

        # Manual construction check
        ph = PostHocTest(1:5, 1:5; cld = true)
        tt = PostHocTestResult(ph.method, ph.comparisons, ph.alpha, ph.use_cld, ph.cld_letters, Dict{Int64, String}())
        df_tt = GroupTestToDataframe(tt)
        @test nrow(df_tt) == 2
    end

    # ==========================================================================
    # Non-Parametric Post-Hoc Tests
    # ==========================================================================
    @testset "PostHoc Non-Parametric - Raw" begin
        g1 = rand(10)
        g2 = rand(10) .+ 0.5
        g3 = rand(10)
        
        res_dunn = PostHocNonPar(g1, g2, g3; method=:dunn_bonferroni)
        @test res_dunn.method == :dunn_bonferroni
        
        res_nemenyi = PostHocNonPar([g1, g2, g3]; method=:nemenyi)
        @test res_nemenyi.method == :nemenyi

        res_dunn_simple = PostHocNonPar([g1, g2, g3]; method=:dunn)
        @test res_dunn_simple.method == :dunn

        res_sidak = PostHocNonPar([g1, g2, g3]; method=:dunn_sidak, cld=true)
        @test res_sidak.method == :dunn_sidak
    end

    # ==========================================================================
    # Contingency Post-Hoc (Row & Cell)
    # ==========================================================================
    @testset "PostHoc Contingency - Raw Matrix" begin
        tbl = [20 10 5; 10 20 5; 5 5 20]
        
        # Cell-Level (ASR)
        asr_cell = PostHocContingencyCell(tbl; method=:asr, adjustment=:bonferroni)
        @test asr_cell isa ContingencyCellTestResult
        @test sprint(show, asr_cell)[1:70] == "\n========================================\nPost-hoc Cell Analysis: :asr"

        # Cell-Level (Fisher 1vsAll)
        fisher_cell = PostHocContingencyCell(tbl; method=:fisher_1vsall, adjustment=:bonferroni)
        @test fisher_cell isa ContingencyCellTestResult
        
        # Results to DataFrame
        res_cell = asr_cell
        df_long = DataFrame(res_cell)
        @test nrow(df_long) == 9 
        df_mat = CellTestToDataframe(res_cell)
        @test nrow(df_mat) == 3

        # Row-Level
        res_row = PostHocContingencyRow(tbl; method=:chisq, adjustment=:bh)
        @test res_row isa PostHocTestResult
        @test length(res_row.comparisons) == 3 
        
        # Row-Level (Fisher & CLD)
        fisher_row = PostHocContingencyRow(tbl; method=:fisher, adjustment=:bh, cld=true)
        @test fisher_row isa PostHocTestResult
    end

    # ==========================================================================
    # Misc
    # ==========================================================================
    @testset "Misc Functions" begin
        randP = randn(5)
        @test HypothesisTestsExtra.adjust_pvalues(randP, :none) == randP
        @test_throws ErrorException HypothesisTestsExtra.adjust_pvalues(randP, :abc)
    end
end
