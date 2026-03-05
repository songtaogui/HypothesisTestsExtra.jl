#FILEPATH: test/common/test_formatters_and_helpers.jl

@testset "Common: formatters and helper-facing APIs" begin
    @testset "PostHoc result formatters" begin
        g1 = randn(20)
        g2 = randn(20) .+ 2
        g3 = randn(20) .- 1

        res = PostHocPar(g1, g2, g3; method=:tukey, cld=true)
        @test res isa PostHocTestResult

        df_long = DataFrame(res)
        @test nrow(df_long) == 3
        @test "Contrast" in names(df_long)
        @test "P-value" in names(df_long)

        df_group = GroupTestToDataframe(res)
        @test "GroupLabel" in names(df_group)
        @test "CLD" in names(df_group)
    end

    @testset "Contingency formatter output" begin
        tbl = [20 10 5; 10 20 5; 5 5 20]
        res_cell = PostHocContingencyCell(tbl; method=:asr_bonferroni)

        df_long = DataFrame(res_cell)
        @test nrow(df_long) == 9
        @test "Observed" in names(df_long)

        df_mat = CellTestToDataframe(res_cell)
        @test nrow(df_mat) == 3
        @test "RowLabel" in names(df_mat)
    end

    @testset "adjust_pvalues" begin
        randP = randn(5)
        @test HypothesisTestsExtra.adjust_pvalues(randP, :none) == randP
        @test_throws ErrorException HypothesisTestsExtra.adjust_pvalues(randP, :abc)
    end
end
