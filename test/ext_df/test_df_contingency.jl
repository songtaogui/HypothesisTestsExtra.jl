#FILEPATH: test/ext_df/test_df_contingency.jl

@testset "DataFrame extension: contingency wrappers" begin
    df_cat = DataFrame(
        r = ["A","A","B","B","A","B","A","B"],
        c = ["X","Y","X","Y","X","Y","Y","X"]
    )

    @test ChisqTest(df_cat, :r, :c) isa PowerDivergenceTest
    @test FisherExactTest(df_cat[df_cat.c .!= "Y" .|| df_cat.r .!= "A", :], :r, :c) isa FisherExactTest
    @test FisherExactTestRxC(df_cat, :r, :c) isa FisherExactTestRxC
    @test PowerDivergenceTest(df_cat, :r, :c) isa PowerDivergenceTest

    df_freq = DataFrame(
        r = ["A","A","B","B"],
        c = ["X","Y","X","Y"],
        n = [10, 5, 2, 8]
    )

    @test ChisqTest(df_freq, :r, :c, :n) isa PowerDivergenceTest
    @test FisherExactTest(df_freq, :r, :c, :n) isa FisherExactTest
    @test FisherExactTestRxC(df_freq, :r, :c, :n) isa FisherExactTestRxC
    @test PowerDivergenceTest(df_freq, :r, :c, :n) isa PowerDivergenceTest

    @test PostHocContingencyRow(df_cat, :r, :c) isa PostHocTestResult
    @test PostHocContingencyCell(df_cat, :r, :c) isa ContingencyCellTestResult
end
