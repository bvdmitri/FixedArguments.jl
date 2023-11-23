# FixedArguments

[![Build Status](https://github.com/bvdmitri/FixedArgumentsCallable.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/bvdmitri/FixedArgumentsCallable.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/bvdmitri/FixedArgumentsCallable.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/bvdmitri/FixedArgumentsCallable.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

This package serves as a straightforward and lightweight extension of Julia's Base.Fix1 and Base.Fix2 functionalities.

Similar projects:

- [`FixArgs.jl`](https://github.com/goretkin/FixArgs.jl)
- [`ChainedFixes.jl`](https://github.com/Tokazama/ChainedFixes.jl)
- [`AccessorsExtra.jl`](https://github.com/JuliaObjects/Accessors.jl)

The key distinction of this package is its simplicity and lightweight design. Its single purpose is to generate __a function with fixed values__ for specific arguments __programmatically__, incurring __no additional computational overhead__. Notably, it is not using macro-based sugar-syntax in favor of an ultra-minimalistic API. Additionally, the package offers the ability to modify fixed values using a custom transform function.

## Simple example

Consider a basic function where you wish to set specific arguments:

```julia
foo(x, y, z) = x * y + z
```

This package supports two fixing methods: position-based fixing and sequential-based fixing.

### Position-based Fixing

Suppose you want to fix the first and third arguments of this function. Using position-based fixing, it would look like this:

```julia
import FixedArguments: fix, FixedArgument

# Fixes the argument at position `1` with the value `1.0`
#       the argument at position `3` with the value `3.0`
fixed_foo = fix(foo, (FixedArgument(1, 1.0), FixedArgument(2, 3.0))) 
```

The resulting function can be called as 

```julia
fixed_foo(2.0) # 5.0
```

**Note**: While not strictly necessary, for optimal performance and to avoid dynamic dispatch, it is recommended to have positions known at compile-time. Also, ensure that positions are specified in ascending order.

### Sequential based fixing

For sequential-based fixing, the same example would be written as:

```julia
# Fixes the argument at position `1` with the value `1.0`
#       the argument at position `2` is not being fixed
#       the argument at position `3` with the value `3.0`
fixed_foo = fix(foo, (FixedArgument(1.0), NotFixed(), FixedArgument(3.0))) 
```

**Note**: Both scenarios are valid, but to prevent ambiguity, position-based and sequential-based fixing methods are not compatible. 
Attempting to combine them will result in an error:

```julia
fix(foo, (FixedArgument(1.0), FixedArgument(2, 1.0))) # throws an error
```

The `NoFixed()` argument can be employed in both regimes, but in the position-based regime, it is simply disregarded.

### Custom transformation of the fixed values

The `fix` function also accepts a custom transformation function as its second argument, which gets called each time the fixed arguments are placed in their respective slots. The default transformation function doesn't alter anything and simply returns the fixed value (aka `identity`), but in more complex scenarious it provides the ability to dynamically change the fixed values based on their position. For instance:

```julia
import FixedArguments: FixedPosition

function unpack_from_cache_instead(::FixedPosition{P}, cache) where {P}
    return cache[P]
end

some_global_cache = Dict()

some_global_cache[1] = 1.0
some_global_cache[2] = 2.0
some_global_cache[3] = 3.0

cached_foo = fix(foo, unpack_from_cache_instead, (FixedArgument(some_global_cache), FixedArgument(some_global_cache), FixedArgument(some_global_cache)))

cached_foo() # 5.0

some_global_cache[1] = 3.0
some_global_cache[2] = 2.0
some_global_cache[3] = 1.0

cached_foo() # 7.0
```

**Note** The object that is returned from the `fix` function is not a subtype of `Function`.