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

@testitem "Check dynamic positionning" begin
    import FixedArguments: fix, FixedArgument

    foo(x, y, z) = x * y + z
    
    positions = [ 1, 2, 3 ]
    values = [ 1.0, 2.0, 3.0 ]
    
    arguments = (map(d -> FixedArgument(d[1], d[2]), zip(positions, values))..., )

    fixed_foo = fix(foo, arguments)

    @test fixed_foo() == 5.0
end

@testitem "Cache based transform (example from the README)" begin 
    import FixedArguments: fix, FixedArgument, FixedPosition

    function unpack_from_cache_instead(::FixedPosition{P}, cache) where {P}
        return cache[P]
    end

    foo(x, y, z) = x * y + z
    
    some_global_cache = Dict()
    
    some_global_cache[1] = 1.0
    some_global_cache[2] = 2.0
    some_global_cache[3] = 3.0

    cached_foo = fix(foo, unpack_from_cache_instead, (FixedArgument(some_global_cache), FixedArgument(some_global_cache), FixedArgument(some_global_cache)))

    @test cached_foo() == 5.0

    some_global_cache[1] = 3.0
    some_global_cache[2] = 2.0
    some_global_cache[3] = 1.0

    @test cached_foo() == 7.0
end

@testitem "Test zero allocations" begin
    import FixedArguments: fix, FixedArgument, NotFixed, AutoPosition, FixedPosition
    import AllocCheck: check_allocs

    foo(x, y, z) = x * y + z

    @test length(check_allocs(fix, (typeof(foo), Tuple{}))) === 0
    @test length(check_allocs(fix, (typeof(foo), Tuple{NotFixed}))) === 0
    @test length(check_allocs(fix, (typeof(foo), Tuple{FixedArgument{1}, Int}))) === 0
    @test length(check_allocs(fix, (typeof(foo), Tuple{FixedArgument{1, Int}, FixedArgument{2, Int}}))) === 0
    @test length(check_allocs(fix, (typeof(foo), Tuple{FixedArgument{AutoPosition, Int}}))) === 0
    @test length(check_allocs(fix, (typeof(foo), Tuple{FixedArgument{AutoPosition, Int}, FixedArgument{AutoPosition, Int}}))) === 0

    @test length(check_allocs(fix(foo, (FixedArgument(1), FixedArgument(2))), (Int,))) === 0
    @test length(check_allocs(fix(foo, (FixedArgument(1), FixedArgument(2))), (Float64,))) === 0
    @test length(check_allocs(fix(foo, (FixedArgument(1), )), (Int, Int))) === 0
    @test length(check_allocs(fix(foo, (FixedArgument(1), )), (Float64, Float64))) === 0

    @test length(check_allocs(fix(foo, (_, x) -> 1, (FixedArgument(1), FixedArgument(2))), (Int,))) === 0
    @test length(check_allocs(fix(foo, (_, x) -> 1, (FixedArgument(1), FixedArgument(2))), (Float64,))) === 0
    @test length(check_allocs(fix(foo, (_, x) -> 1, (FixedArgument(1), )), (Int, Int))) === 0
    @test length(check_allocs(fix(foo, (_, x) -> 1, (FixedArgument(1), )), (Float64, Float64))) === 0

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