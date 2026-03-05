#FILEPATH: test/ext_categorical/test_categorical_typesafety.jl

@testset "Categorical extension: type safety for ordered requirements" begin
    df_mixed = DataFrame(
        Unordered = categorical(["A", "B", "C"], ordered=false),
        Ordered = categorical(["Low", "Med", "High"], ordered=true),
        Numeric = [1.0, 2.0, 3.0],
        StringCol = ["X", "Y", "Z"],
        Binary = categorical([0, 1, 0])
    )

    @test_throws ArgumentError JonckheereTerpstraTest(df_mixed, :Unordered, :Numeric)
    @test_throws ArgumentError CochranArmitageTest(df_mixed, :Unordered, :Binary)
    @test_throws ArgumentError LinearByLinearTest(df_mixed, :Unordered, :Ordered)
end
