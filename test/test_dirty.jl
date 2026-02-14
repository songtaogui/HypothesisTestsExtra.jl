# test/test_dirty.jl


# ==============================================================================
# 4. Data Cleaning & Dirty Data Handling
# ==============================================================================
@testset "Data Cleaning & Robustness" begin
    df_dirty = DataFrame(
        group = categorical(["A", "A", "A", "B", "B", "B", "C", "C", "C"]),
        score = [10.5, NaN, 12.0, missing, 15.0, 16.5, 20.0, 21.0, nothing],
        ordered_group = categorical(["Low", "Low", "Med", "Med", "High", "High", "Med", "High", "High"], ordered=true),
        binary_outcome = categorical([1, 0, missing, 1, 0, 1, 1, 0, 1]),
        weight = [10, 20, 30, 10, 20, 30, 10, 20, 30]
    )

    # T-Test: Verify automatic removal of NaN/missing/nothing
    # Group A: [10.5, 12.0], Group B: [15.0, 16.5]
    df_ab = filter(row -> row.group != "C", df_dirty)
    t_test = EqualVarianceTTest(df_ab, :group, :score)
    @test t_test.n_x == 2
    @test t_test.n_y == 2
    @test !isnan(pvalue(t_test))

    # K-Sample Test: KruskalWallis
    # Group C: [20.0, 21.0]. Total N = 2(A) + 2(B) + 2(C) = 6
    kw_test = KruskalWallisTest(df_dirty, :group, :score)
    @test sum(kw_test.n_i) == 6

    # GroupedDataFrame Dispatch Consistency
    gd = groupby(df_dirty, :group)
    @test pvalue(OneWayANOVATest(gd, :score)) ≈ pvalue(OneWayANOVATest(df_dirty, :group, :score))
    
    # Categorical Tests with missing values
    # Should only count rows where both are valid
    chi2 = ChisqTest(df_dirty, :ordered_group, :binary_outcome)
    @test sum(chi2.observed) == 8 # 9 rows - 1 missing in binary_outcome
end