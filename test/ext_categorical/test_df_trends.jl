#FILEPATH: test/ext_categorical/test_df_trends.jl

@testset "Categorical extension: DataFrame trend/association tests" begin
    # 1. Jonckheere-Terpstra
    df_jt = DataFrame(
        dose = categorical(["Low", "Low", "Med", "Med", "High", "High"], ordered=true),
        resp = [1.2, 1.4, NaN, 2.5, 3.1, missing]
    )
    jt = JonckheereTerpstraTest(df_jt, :dose, :resp)
    @test jt.n_total == 4 
    @test jt.n_groups == 3

    # 2. Cochran-Armitage
    df_ca = DataFrame(
        dose = categorical(["Low", "Low", "Med", "Med", "High", "High"], ordered=true),
        success = categorical([0, 0, 1, 0, 1, 1])
    )
    ca = CochranArmitageTest(df_ca, :dose, :success)
    @test sum(ca.n_total) == 6

    # 3. Linear-by-Linear
    df_lbl = DataFrame(
        row = categorical(["L1", "L1", "L2", "L2", "L3", "L3"], ordered=true),
        col = categorical(["C1", "C2", "C1", "C2", "C1", "C2"], ordered=true),
        freq = [10, 5, 2, 8, 1, 15]
    )
    lbl = LinearByLinearTest(df_lbl, :row, :col, :freq)
    @test lbl.n == sum(df_lbl.freq)
end
