#FILEPATH: test/ext_df/test_df_onesample.jl

@testset "DataFrame extension: one-sample wrappers" begin
    df_one = DataFrame(x = randn(30))
    @test OneSampleTTest(df_one, :x) isa OneSampleTTest
    @test OneSampleZTest(df_one, :x) isa OneSampleZTest
    @test SignTest(df_one, :x) isa SignTest
    @test SignedRankTest(df_one, :x) isa ExactSignedRankTest

    # Use Bool/String to satisfy both ext variants (:binary check)
    df_bin_bool = DataFrame(x = rand([true, false], 40))
    df_bin_str = DataFrame(x = rand(["a", "b"], 40))
    @test BinomialTest(df_bin_bool, :x) isa BinomialTest
    @test BinomialTest(df_bin_str, :x) isa BinomialTest
end
