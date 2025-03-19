using MPSGE
using FileIO
using NamedArrays
using DataFrames

using BenchmarkTools

using JuMP

include("model.jl")

year = 2017



load_time = @benchmark load("WiNDC_household/data_$year.jld2") samples=10


mean(load_time)


data = load("WiNDC_household/data_$year.jld2")

build_time = @benchmark begin
    HH = household_model(data);
    MPSGE.build_constraints!(HH);
end samples=10 seconds=60*10

mean(build_time)

HH = household_model(data);
MPSGE.build_constraints!(HH);


fix(HH[:PFX], 1)

set_silent(HH)

bench_time = @benchmark solve!(HH, cumulative_iteration_limit=0) samples=10 seconds=60*10

mean(bench_time)

for r∈String.(data["sets"]["r"]), h∈String.(data["sets"]["h"])
    set_value!(HH[:tl][r,h], 0.8*data["parameters"]["tl0"][r,h])
end


counter_time = @benchmark solve!(HH) samples=10 seconds=60*12

print("
Load time: $(mean(load_time))
Build time: $(mean(build_time))
Benchmark time: $(mean(bench_time))
Counterfactual time: $(mean(counter_time))

Total time: $(mean(load_time) + mean(build_time) + mean(bench_time) + mean(counter_time))
")

