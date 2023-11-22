module FixedArguments

using TupleTools

"""
FixedCallable(fn, fixedargs, [ unpack ])
"""
struct FixedCallable{F,A,U}
    fn::F
    unpack::U
    fixedargs::A
end

function (callable::FixedCallable)(args...)
    return callable.fn(inject_arguments(callable.unpack, args, callable.fixedargs)...)
end

struct NotFixed end
struct AutoPosition end
struct FixedPosition{P} end

FixedPosition(position::Integer) = FixedPosition{position}()

struct FixedArgument{P,V}
    position::P
    value::V
end

FixedArgument(value::V) where {V} = FixedArgument(AutoPosition(), value)
function FixedArgument(position::Integer, value::V) where {V}
    return FixedArgument(FixedPosition(position), value)
end

position(argument::FixedArgument) = argument.position
value(argument::FixedArgument) = argument.value

default_unpack(_, value) = value

function fix(fn::F, fixedargs::Tuple) where {F}
    return fix(fn, default_unpack, fixedargs)
end

function fix(fn::F, unpack::U, fixedargs::Tuple) where {F,U}
    _fixedargs = process_fixedargs(fixedargs)
    _checked_fixedargs = check_ascending_args(_fixedargs)
    return FixedCallable(fn, unpack, _checked_fixedargs)
end

# We do not want to mix `FixedArgument`s with different positioning regimes
# FixedArgument(position, value) - switches to the `ExactPositioningRegime`
# FixedArgument(value) - switches to the `AutoPositioningRegime`
# Before we start processing the arguments we don't really know what regime to use 
# so by default the regime is `UnknownPositioningRegime`
struct UnknownPositioningRegime end
struct ExactPositioningRegime end
struct AutoPositioningRegime end

struct MixedFixedArgumentsException <: Exception end

function Base.showerror(io::IO, ::MixedFixedArgumentsException)
    return print(io, "Cannot mix number-based positioning and auto-based positioning")
end

function check_regime(::UnknownPositioningRegime, argument::FixedArgument)
    return check_regime(UnknownPositioningRegime(), position(argument))
end
function check_regime(::ExactPositioningRegime, argument::FixedArgument)
    return check_regime(ExactPositioningRegime(), position(argument))
end
function check_regime(::AutoPositioningRegime, argument::FixedArgument)
    return check_regime(AutoPositioningRegime(), position(argument))
end

function check_regime(::UnknownPositioningRegime, ::NotFixed)
    return UnknownPositioningRegime()
end
function check_regime(::UnknownPositioningRegime, ::FixedPosition)
    return ExactPositioningRegime()
end
function check_regime(::UnknownPositioningRegime, ::AutoPosition)
    return AutoPositioningRegime()
end

function check_regime(::ExactPositioningRegime, ::NotFixed)
    return ExactPositioningRegime()
end
function check_regime(::ExactPositioningRegime, ::AutoPosition)
    throw(MixedFixedArgumentsException())
end
function check_regime(::ExactPositioningRegime, ::FixedPosition)
    return ExactPositioningRegime()
end

function check_regime(::AutoPositioningRegime, ::NotFixed)
    return AutoPositioningRegime()
end
function check_regime(::AutoPositioningRegime, ::AutoPosition)
    return AutoPositioningRegime()
end
function check_regime(::AutoPositioningRegime, ::FixedPosition)
    throw(MixedFixedArgumentsException())
end

# Start processing with the first argument
function process_fixedargs(fixedargs::Tuple)
    return process_fixedargs(Val(1), UnknownPositioningRegime(), (), fixedargs)
end

# We end if there is nothing to process
function process_fixedargs(::Val{N}, regime, processed, fixedargs::Tuple{}) where {N}
    return processed
end

# For each iteration split the arguments into the current and the remaining
# Additionally we check if the next argument is compatible with the current regime 
function process_fixedargs(::Val{N}, regime, processed, fixedargs::Tuple) where {N}
    current = first(fixedargs)
    remaining = Base.tail(fixedargs)
    checked_regime = check_regime(regime, current)
    return process_fixedargs(Val(N), checked_regime, processed, current, remaining)
end

# If the argument is not fixed simply skip it
function process_fixedargs(::Val{N}, regime, processed, current::NotFixed, remaining::Tuple) where {N}
    return process_fixedargs(Val(N + 1), regime, processed, remaining)
end

# Extract the position for the current fixed argument
function process_fixedargs(::Val{N}, regime, processed, current::FixedArgument, remaining::Tuple) where {N}
    return process_fixedargs(Val(N), regime, processed, position(current), current, remaining)
end

# If the argument already has a fixed position simply include it in the list of fixed arguments
function process_fixedargs(
    ::Val{N}, regime, processed, ::FixedPosition, current::FixedArgument, remaining::Tuple
) where {N}
    return process_fixedargs(Val(N + 1), regime, (processed..., current), remaining)
end

# If the argument already has the auto position spec use the current iteration number as its position
function process_fixedargs(
    ::Val{N}, regime, processed, ::AutoPosition, current::FixedArgument, remaining::Tuple
) where {N}
    return process_fixedargs(Val(N), regime, processed, FixedArgument(N, value(current)), remaining)
end

# Check ascending args function checks that the argument are aligned in the ascending order
check_ascending_args(fixedargs) = check_ascending_args(Val(1), (), fixedargs)

check_ascending_args(::Val{N}, checked, fixedargs::Tuple{}) where {N} = checked

function check_ascending_args(::Val{N}, checked, fixedargs::Tuple) where {N}
    return check_ascending_args(Val(N), checked, first(fixedargs), Base.tail(fixedargs))
end

function check_ascending_args(::Val{N}, checked::Tuple{}, current::FixedArgument, remaining::Tuple) where {N}
    return check_ascending_args(Val(N), checked, FixedPosition(0), position(current), current, remaining)
end
function check_ascending_args(::Val{N}, checked, current::FixedArgument, remaining::Tuple) where {N}
    return check_ascending_args(Val(N), checked, position(last(checked)), position(current), current, remaining)
end

function check_ascending_args(
    ::Val{N}, checked, ::FixedPosition{Pr}, ::FixedPosition{Pc}, current::FixedArgument, remaining::Tuple
) where {N,Pr,Pc}
    N >= length(checked) && (Pc >= length(checked)) && (Pc >= N) && (Pr < Pc) ||
        throw(ErrorException("Fixed position $Pc is not in ascending order (previous was $Pr)"))
    return check_ascending_args(Val(N + 1), (checked..., current), remaining)
end

# Inject arguments function injects the fixed arguments into the argument list
# Optionally applies the unpack function
inject_arguments(::F, args::Tuple, ::Tuple{}) where {F} = args

function inject_arguments(unpack::F, args::Tuple, fixedargs::Tuple) where {F}
    return inject_arguments(unpack, args, first(fixedargs), Base.tail(fixedargs))
end

function inject_arguments(unpack::F, args::Tuple, current::FixedArgument, remaining) where {F}
    return inject_arguments(unpack, args, position(current), current, remaining)
end

function inject_arguments(
    unpack::F, args::Tuple, position::FixedPosition{P}, current::FixedArgument, remaining
) where {F,P}
    newargs = TupleTools.insertafter(args, P - 1, (unpack(position, value(current)),))
    return inject_arguments(unpack, newargs, remaining)
end

end
