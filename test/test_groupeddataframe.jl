@testset "GroupedDataFrame Extensions" begin

    # ==========================================================================
    # Setup Data
    # ==========================================================================
    # 1. Dataset for 3 groups (ANOVA, PostHoc, etc.)
    df_3 = DataFrame(
        g = vcat(fill("A", 10), fill("B", 10), fill("C", 10)),
        x = randn(30)
    )
    gd_3 = groupby(df_3, :g)

    # 2. Dataset for 2 groups (T-Test, etc.)
    df_2 = DataFrame(
        g = vcat(fill("A", 10), fill("B", 10)),
        x = randn(20)
    )
    gd_2 = groupby(df_2, :g)

    # 3. Dataset for Categorical Tests (RxC)
    df_cat = DataFrame(
        row = vcat(fill("R1", 20), fill("R2", 20)),
        col = rand(["C1", "C2", "C3"], 40) # 3 levels to ensure RxC
    )
    gd_cat = groupby(df_cat, :row)

    # 4. Dataset for 2x2 Fisher Exact Test
    df_2x2 = DataFrame(
        row = vcat(fill("G1", 10), fill("G2", 10)),
        col = vcat(rand(["Yes", "No"], 10), rand(["Yes", "No"], 10))
    )
    gd_2x2 = groupby(df_2x2, :row)

    # ==========================================================================
    # 1. Post-Hoc Tests (Numerical)
    # ==========================================================================
    @testset "PostHoc Tests - GD" begin
        # Parametric: Tukey
        res_gd = PostHocTest(gd_3, :x; method=:tukey)
        @test res_gd isa PostHocTestResult
        @test length(res_gd.comparisons) == 3

        # Parametric: Tukey (Explicit Group Column)
        res_gd_overload = PostHocTest(gd_3, :g, :x; method=:tukey)
        @test res_gd_overload isa PostHocTestResult

        # Non-Parametric: Dunn
        res_np_gd = PostHocNonPar(gd_3, :x; method=:dunn)
        @test res_np_gd isa PostHocTestResult
        @test length(res_np_gd.comparisons) == 3
        
        # Non-Parametric: Dunn (Explicit Group Column)
        res_np_gd_overload = PostHocNonPar(gd_3, :g, :x; method=:dunn)
        @test res_np_gd_overload isa PostHocTestResult
    end

    # ==========================================================================
    # 2. Contingency Post-Hoc (Categorical)
    # ==========================================================================
    @testset "Contingency PostHoc - GD" begin
        # Row-Level Analysis
        res_row = PostHocContingencyRow(gd_cat, :col; method=:chisq)
        @test res_row isa PostHocTestResult
        
        # Row-Level Analysis (Explicit Row Column)
        res_row_overload = PostHocContingencyRow(gd_cat, :row, :col; method=:chisq)
        @test res_row_overload isa PostHocTestResult

        # Cell-Level Analysis (Adjusted Standardized Residuals)
        res_cell = PostHocContingencyCell(gd_cat, :col; method=:asr)
        @test res_cell isa ContingencyCellTestResult

        # Cell-Level Analysis (Explicit Row Column)
        res_cell_overload = PostHocContingencyCell(gd_cat, :row, :col; method=:asr)
        @test res_cell_overload isa ContingencyCellTestResult
    end

    # ==========================================================================
    # 3. Standard Categorical Tests
    # ==========================================================================
    @testset "Categorical Tests - GD" begin
        # Pearson Chi-square
        @test ChisqTest(gd_cat, :col) isa PowerDivergenceTest
        # Pearson Chi-square (Explicit Row Column)
        @test ChisqTest(gd_cat, :row, :col) isa PowerDivergenceTest
        
        # Fisher Exact Test (2x2)
        @test FisherExactTest(gd_2x2, :col) isa FisherExactTest
        # Fisher Exact Test (2x2) (Explicit Row Column)
        @test FisherExactTest(gd_2x2, :row, :col) isa FisherExactTest

        # Fisher Exact Test (RxC)
        @test FisherExactTestRxC(gd_cat, :col) isa FisherExactTestMC
        # Fisher Exact Test (RxC) (Explicit Row Column)
        @test FisherExactTestRxC(gd_cat, :row, :col) isa FisherExactTestMC

        # Power Divergence
        @test PowerDivergenceTest(gd_cat, :col) isa PowerDivergenceTest
        # Power Divergence (Explicit Row Column)
        @test PowerDivergenceTest(gd_cat, :row, :col) isa PowerDivergenceTest
    end

    # ==========================================================================
    # 4. K-Sample & Variance Tests
    # ==========================================================================
    @testset "K-Sample & Variance - GD" begin
        # ANOVA Family
        @test OneWayANOVATest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest
        # ANOVA Family (Explicit Group Column)
        @test OneWayANOVATest(gd_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
        
        @test WelchANOVATest(gd_3, :x) isa WelchANOVATest
        # Welch ANOVA (Explicit Group Column)
        @test WelchANOVATest(gd_3, :g, :x) isa WelchANOVATest

        @test KruskalWallisTest(gd_3, :x) isa KruskalWallisTest
        # Kruskal-Wallis (Explicit Group Column)
        @test KruskalWallisTest(gd_3, :g, :x) isa KruskalWallisTest

        # Variance Homogeneity Tests
        @test LeveneTest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest
        # Levene (Explicit Group Column)
        @test LeveneTest(gd_3, :g, :x) isa HypothesisTests.VarianceEqualityTest

        @test BrownForsytheTest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest
        # Brown-Forsythe (Explicit Group Column)
        @test BrownForsytheTest(gd_3, :g, :x) isa HypothesisTests.VarianceEqualityTest

        @test FlignerKilleenTest(gd_3, :x) isa HypothesisTests.VarianceEqualityTest
        # Fligner-Killeen (Explicit Group Column)
        @test FlignerKilleenTest(gd_3, :g, :x) isa HypothesisTests.VarianceEqualityTest
    end

    # ==========================================================================
    # 5. Two-Sample Tests
    # ==========================================================================
    @testset "Two-Sample - GD" begin
        # T-Tests
        @test EqualVarianceTTest(gd_2, :x) isa EqualVarianceTTest
        # Equal Variance T-Test (Explicit Group Column)
        @test EqualVarianceTTest(gd_2, :g, :x) isa EqualVarianceTTest

        @test UnequalVarianceTTest(gd_2, :x) isa UnequalVarianceTTest
        # Unequal Variance T-Test (Explicit Group Column)
        @test UnequalVarianceTTest(gd_2, :g, :x) isa UnequalVarianceTTest
        
        # F-Test
        @test VarianceFTest(gd_2, :x) isa VarianceFTest
        # F-Test (Explicit Group Column)
        @test VarianceFTest(gd_2, :g, :x) isa VarianceFTest
        
        # Non-Parametric Two-Sample
        @test MannWhitneyUTest(gd_2, :x) isa ExactMannWhitneyUTest
        # Mann-Whitney U (Explicit Group Column)
        @test MannWhitneyUTest(gd_2, :g, :x) isa ExactMannWhitneyUTest
        
        # KS Test
        @test ApproximateTwoSampleKSTest(gd_2, :x) isa ApproximateTwoSampleKSTest
        # KS Test (Explicit Group Column)
        @test ApproximateTwoSampleKSTest(gd_2, :g, :x) isa ApproximateTwoSampleKSTest

        @test_throws ErrorException EqualVarianceTTest(gd_3, :x)
    end
end
