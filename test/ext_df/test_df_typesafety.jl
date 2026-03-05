#FILEPATH: test/ext_df/test_df_typesafety.jl

@testset "DataFrame extension: type safety (non-categorical specific)" begin
    df = DataFrame(
        g = ["A", "B", "C"],
        x = [1.0, 2.0, 3.0],
        s = ["X", "Y", "Z"],
        b = [true, false, true]
    )

    @test_throws ArgumentError OneWayANOVATest(df, :g, :s)
    @test_throws ArgumentError EqualVarianceTTest(df, :g, :s)
    @test_throws ArgumentError BinomialTest(DataFrame(x=[1,2,3]), :x)
end
