#FILEPATH: test/ext_df/test_df_dirty.jl

@testset "DataFrame extension: dirty data cleaning behavior" begin
    df_dirty = DataFrame(
        group = ["A", "A", "A", "B", "B", "B", "C", "C", "C"],
        score = [10.5, NaN, 12.0, missing, 15.0, 16.5, 20.0, 21.0, nothing],
        cat_group = ["Low", "Low", "Med", "Med", "High", "High", "Med", "High", "High"],
        binary_outcome = [1, 0, missing, 1, 0, 1, 1, 0, 1],
        weight = [10, 20, 30, 10, 20, 30, 10, 20, 30]
    )

    df_ab = filter(row -> row.group != "C", df_dirty)
    t_test = EqualVarianceTTest(df_ab, :group, :score)
    @test t_test.n_x == 2
    @test t_test.n_y == 2
    @test !isnan(pvalue(t_test))

    kw_test = KruskalWallisTest(df_dirty, :group, :score)
    @test sum(kw_test.n_i) == 6

    gd = groupby(df_dirty, :group)
    @test pvalue(OneWayANOVATest(gd, :score)) ≈ pvalue(OneWayANOVATest(df_dirty, :group, :score))
end
