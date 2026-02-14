# test/test_type_errors.jl

# ==============================================================================
# 3. Type Safety & Requirement Assertions
# ==============================================================================
@testset "Type Safety & Requirement Assertions" begin
    # Test data with mismatched types
    df_mixed = DataFrame(
        Unordered = categorical(["A", "B", "C"], ordered=false),
        Ordered = categorical(["Low", "Med", "High"], ordered=true),
        Numeric = [1.0, 2.0, 3.0],
        StringCol = ["X", "Y", "Z"],
        MultiClass = categorical([1, 2, 3], ordered=false),
        Binary = categorical([0, 1, 0])
    )

    # 1. Jonckheere-Terpstra requires Ordered Group
    # Note: If called on DF, IV must be Ordered
    @test_throws ArgumentError JonckheereTerpstraTest(df_mixed, :Unordered, :Numeric)
    
    # 2. ANOVA requires Numeric Data
    @test_throws ArgumentError OneWayANOVATest(df_mixed, :Unordered, :StringCol)
    
    # 3. Cochran-Armitage requires Ordered IV and Binary DV
    @test_throws ArgumentError CochranArmitageTest(df_mixed, :Unordered, :Binary)
    
    # 4. Linear-by-Linear requires both to be Ordered
    @test_throws ArgumentError LinearByLinearTest(df_mixed, :Unordered, :Ordered)
end