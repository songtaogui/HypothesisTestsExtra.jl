#FILEPATH: test/ext_categorical/test_gdf_trends.jl

@testset "Categorical extension: GroupedDataFrame trend/association tests" begin
    df_ord = DataFrame(
        dose = categorical(vcat(fill("Low", 20), fill("Mid", 20), fill("High", 20)); ordered=true),
        y = randn(60),
        resp = categorical(rand(["No", "Yes"], 60)),
        ord_col = categorical(rand(["L1", "L2", "L3"], 60); ordered=true)
    )
    gd_ord = groupby(df_ord, :dose)

    @test JonckheereTerpstraTest(gd_ord, :y) isa JonckheereTerpstraTest
    @test CochranArmitageTest(gd_ord, :resp) isa CochranArmitageTest
    @test LinearByLinearTest(gd_ord, :ord_col) isa LinearByLinearTest

    df_ord_freq = combine(groupby(df_ord, [:dose, :resp, :ord_col]), nrow => :n)
    gd_ord_freq = groupby(df_ord_freq, :dose)
    @test CochranArmitageTest(gd_ord_freq, :resp, :n) isa CochranArmitageTest
    @test LinearByLinearTest(gd_ord_freq, :ord_col, :n) isa LinearByLinearTest
end
