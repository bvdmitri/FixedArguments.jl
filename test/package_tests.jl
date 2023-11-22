@testitem "Number-position" begin
    import FixedArguments: fix, FixedArgument

    foo(x, y, z) = x * y + z

    @test foo(1, 2, 3) == 5
    @test foo(1, 2, 3) == @inferred(fix(foo, (FixedArgument(1, 1), FixedArgument(2, 2)))(3))
    @test foo(1, 2, 3) == @inferred(fix(foo, (FixedArgument(2, 2), FixedArgument(3, 3)))(1))
    @test foo(1, 2, 3) == @inferred(fix(foo, (FixedArgument(1, 1), FixedArgument(3, 3)))(2))

    # custom unpack function
    @test foo(1, 1, 3) == @inferred(fix(foo, (_, x) -> 1, (FixedArgument(1, 1), FixedArgument(2, 2)))(3))
    @test foo(1, 1, 1) == @inferred(fix(foo, (_, x) -> 1, (FixedArgument(2, 2), FixedArgument(3, 3)))(1))
    @test foo(1, 2, 1) == @inferred(fix(foo, (_, x) -> 1, (FixedArgument(1, 1), FixedArgument(3, 3)))(2))
end

@testitem "Auto-positioning" begin
    import FixedArguments: fix, FixedArgument, NotFixed

    foo(x, y, z) = x * y + z

    @test foo(1, 2, 3) == 5
    @test foo(1, 2, 3) == @inferred(fix(foo, (FixedArgument(1), FixedArgument(2), NotFixed()))(3))
    @test foo(1, 2, 3) == @inferred(fix(foo, (NotFixed(), FixedArgument(2), FixedArgument(3)))(1))
    @test foo(1, 2, 3) == @inferred(fix(foo, (FixedArgument(1), NotFixed(), FixedArgument(3)))(2))

    @test foo(1, 1, 3) == @inferred(fix(foo, (_, x) -> 1, (FixedArgument(1), FixedArgument(2), NotFixed()))(3))
    @test foo(1, 1, 1) == @inferred(fix(foo, (_, x) -> 1, (NotFixed(), FixedArgument(2), FixedArgument(3)))(1))
    @test foo(1, 2, 1) == @inferred(fix(foo, (_, x) -> 1, (FixedArgument(1), NotFixed(), FixedArgument(3)))(2))
end

@testitem "Non-ascending order should error" begin
    import FixedArguments: fix, FixedArgument

    foo(x, y, z) = x * y + z

    @test_throws ErrorException fix(foo, (FixedArgument(2, 2), FixedArgument(1, 1)))
    @test_throws ErrorException fix(foo, (FixedArgument(3, 3), FixedArgument(1, 1)))
    @test_throws ErrorException fix(foo, (FixedArgument(3, 3), FixedArgument(2, 2)))
end

@testitem "Mixing number-positioning and auto-positioning is dis-allowed" begin
    import FixedArguments: fix, FixedArgument, NotFixed, MixedFixedArgumentsException

    foo(x, y, z) = x * y + z

    @test foo(1, 2, 3) == 5

    @test_throws MixedFixedArgumentsException fix(foo, (NotFixed(), FixedArgument(2, 2), FixedArgument(3)))
    @test_throws MixedFixedArgumentsException fix(foo, (NotFixed(), FixedArgument(2), FixedArgument(3, 3)))

    @test_throws MixedFixedArgumentsException fix(foo, (FixedArgument(1, 1), NotFixed(), FixedArgument(3)))
    @test_throws MixedFixedArgumentsException fix(foo, (FixedArgument(1), NotFixed(), FixedArgument(3, 3)))
end

@testitem "Test zero allocations" begin
    import FixedArguments: fix, FixedArgument
    import AllocCheck: check_allocs

    foo(x, y, z) = x * y + z

    @test length(check_allocs(fix(foo, (FixedArgument(1, 1), FixedArgument(2, 2))), (Int,))) === 0
    @test length(check_allocs(fix(foo, (FixedArgument(1, 1), FixedArgument(2, 2))), (Float64,))) === 0
    @test length(check_allocs(fix(foo, (FixedArgument(2, 2), FixedArgument(3, 3))), (Int,))) === 0
    @test length(check_allocs(fix(foo, (FixedArgument(2, 2), FixedArgument(3, 3))), (Float64,))) === 0
    @test length(check_allocs(fix(foo, (FixedArgument(1, 1), FixedArgument(3, 3))), (Int,))) === 0
    @test length(check_allocs(fix(foo, (FixedArgument(1, 1), FixedArgument(3, 3))), (Float64,))) === 0

    @test length(check_allocs(fix(foo, (_, x) -> 1, (FixedArgument(1, 1), FixedArgument(2, 2))), (Int,))) === 0
    @test length(check_allocs(fix(foo, (_, x) -> 1, (FixedArgument(1, 1), FixedArgument(2, 2))), (Float64,))) === 0
    @test length(check_allocs(fix(foo, (_, x) -> 1, (FixedArgument(2, 2), FixedArgument(3, 3))), (Int,))) === 0
    @test length(check_allocs(fix(foo, (_, x) -> 1, (FixedArgument(2, 2), FixedArgument(3, 3))), (Float64,))) === 0
    @test length(check_allocs(fix(foo, (_, x) -> 1, (FixedArgument(1, 1), FixedArgument(3, 3))), (Int,))) === 0
    @test length(check_allocs(fix(foo, (_, x) -> 1, (FixedArgument(1, 1), FixedArgument(3, 3))), (Float64,))) === 0
end