#FILEPATH: test/ext_df/test_gdf_contingency.jl

@testset "GroupedDataFrame extension: contingency wrappers" begin
    df_cat = DataFrame(
        row = vcat(fill("R1", 20), fill("R2", 20)),
        col = rand(["C1", "C2", "C3"], 40)
    )
    gd_cat = groupby(df_cat, :row)

    @test ChisqTest(gd_cat, :col) isa PowerDivergenceTest
    @test FisherExactTestRxC(gd_cat, :col) isa FisherExactTestRxC
    @test PowerDivergenceTest(gd_cat, :col) isa PowerDivergenceTest
    @test PostHocContingencyRow(gd_cat, :col; method=:chisq) isa PostHocTestResult
    @test PostHocContingencyCell(gd_cat, :col; method=:asr) isa ContingencyCellTestResult

    df_2x2 = DataFrame(
        row = vcat(fill("G1", 10), fill("G2", 10)),
        col = vcat(rand(["Yes", "No"], 10), rand(["Yes", "No"], 10))
    )
    gd_2x2 = groupby(df_2x2, :row)
    @test FisherExactTest(gd_2x2, :col) isa FisherExactTest

    df_cat_freq = combine(groupby(df_cat, [:row, :col]), nrow => :n)
    gd_cat_freq = groupby(df_cat_freq, :row)
    @test ChisqTest(gd_cat_freq, :col, :n) isa PowerDivergenceTest
    @test FisherExactTestRxC(gd_cat_freq, :col, :n) isa FisherExactTestRxC
end
