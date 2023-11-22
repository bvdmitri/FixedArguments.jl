using Aqua, CpuId, ReTestItems, FixedArguments

# `ambiguities = false` - there are quite some ambiguities, but these should be normal and should not be encountered under normal circumstances
# `piracy = false` - we extend/add some of the methods to the objects defined in the Distributions.jl
Aqua.test_all(FixedArguments, deps_compat = (; check_extras = false, check_weakdeps = true))

nthreads = max(cputhreads(), 1)
ncores = max(cpucores(), 1)

runtests(FixedArguments,
    nworkers = ncores,
    nworker_threads = Int(nthreads / ncores),
    memory_threshold = 1.0
)