using MPSGE
using FileIO
using NamedArrays
using DataFrames

using BenchmarkTools

using JuMP

include("model.jl")

year = 2017

data = load("WiNDC_household/data_$year.jld2")

HH = household_model(data);
MPSGE.build_constraints!(HH);


fix(HH[:PFX], 1)

solve!(HH, cumulative_iteration_limit=0)

set_value!.(HH[:tm], .2)

solve!(HH)

df = generate_report(HH)


var = HH[:PC]

function variable_to_dataframe(var::MPSGE.MPSGEIndexedVariable, columns::Symbol...)
    X = Iterators.product(axes(var)...)

    L = []
    for a in X
        push!(L, a)
    end

    df = DataFrame(
        domain = L,
        value = [value(var[a...]) for a in L]
    ) |>
    x -> transform(x,
        :domain => ByRow(identity) => [columns...]
    ) |>
    x -> select(x, [columns..., :value]) 

    return df
end


using PlotlyJS

var = HH[:PC]
df = variable_to_dataframe(var, :state, :household)
PL = variable_to_dataframe(HH[:PL], :state)

X = df |> 
    x -> innerjoin(
        x,
        PL,
        on = :state,
        renamecols = "" => "_wage"
    ) |>
    x -> transform(x,
        [:value, :value_wage] => ByRow((x,y) -> (y/x-1)*100) => :real_value
    ) #
    
X |>
    x -> sort(x, :real_value) |>
    X -> plot(
    X, 
    x = :state, 
    y = :real_value, 
    color = :household, 
    type = :bar, 
    Layout(
        title = var.description,
        #yaxis_range = [bounds[1,:min], bounds[1,:max]])
    )
    )

    #=
bounds = df |>
    x -> combine(x,
        :real_value => maximum => :max,
        :real_value => minimum => :min
    ) |>
    x -> transform(x,
        :max => ByRow(y -> round(y,digits = 2)+5*y/1_000) => :max,
        :min => ByRow(y -> round(y,digits = 2)-5*y/1_000) => :min
    )
=#


G = CSV.read("WiNDC_household/gams/gams_output.csv", DataFrame) |>
    x -> rename(x, :Column1 => :state) |>
    x -> stack(x, Not(:state), variable_name = :household, value_name = :gams)

outerjoin(
    X |>
        x -> select(x, :state, :household, :real_value=> :julia),
    G,
    on = [:state, :household]
) |>
x -> transform(x,
    [:julia, :gams] => ByRow((x,y) -> (y-x)) => :diff
) |>
x -> sort(x, :diff) |>
x -> CSV.write("data_output.csv", x)

plot(
    df, 
    x = :state, 
    y = :value, 
    color = :household, 
    type = :bar, 
    Layout(
        title = var.description,
        yaxis_range = [bounds[1,:min], bounds[1,:max]])
    )


    
var = HH[:PD]
df = variable_to_dataframe(var, :state, :good)


goods = ["ppd", "agr"]
df |>
    x -> subset(x,
        :good => ByRow(in(goods))
    ) |>
    x -> sort(x, :value) |>
    X -> 
plot(
    X, 
    x = :state, 
    y = :value, 
    color = :good, 
    type = :bar, 
    Layout(
        title = var.description,
       # barmode = "relative",
       yaxis_range = [1, 1.15])
    )
)