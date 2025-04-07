using windc_household_model

using DataFrames, MPSGE, PlotlyJS


data = load_data(2017)

M = household_model(data);

#solve!(M, cumulative_iteration_limit=0)

# Set all tariffs to 20%
set_value!.(M[:tm], .2)

solve!(M)


# This could be automated, but needs work to do
vars = Dict(
    :PC => Dict(:domain => (:region, :household)),
    :PLS => Dict(:domain => (:region, :household)),
    :C => Dict(:domain => (:region, :household)),
    :RA => Dict(:domain => (:region, :household)),
    :LS => Dict(:domain => (:region, :household)),
    :PD => Dict(:domain => (:region, :good)),
    :RK => Dict(:domain => (:region, :good)),
    :PY => Dict(:domain => (:region, :good)),
    :X => Dict(:domain => (:region, :good)),
    :A => Dict(:domain => (:region, :good)),
    :PA => Dict(:domain => (:region, :good)),
    :Y => Dict(:domain => (:region, :good)),
    :PM => Dict(:domain => (:region, :margin)),
    :MS => Dict(:domain => (:region, :margin)),
    :PN => Dict(:domain => (:good,)),
    :PL => Dict(:domain => (:region,)),
    :RKS => Dict(:domain => ()),
    :NYSE => Dict(:domain => ()),
    :GOVT_DEMAND => Dict(:domain => ()),
    :GOVT => Dict(:domain => ()),
    :PK => Dict(:domain => ()),
    :KS => Dict(:domain => ()),
    :INVEST_COMMODITY => Dict(:domain => ()),
    :GOVT_COMMODITY => Dict(:domain => ()),
    :PFX => Dict(:domain => ()),
    :INVEST_DEMAND => Dict(:domain => ()),
    :INVEST => Dict(:domain => ()),
)
function var_to_df(M::MPSGEModel, var::Symbol; value = :value, var_dict = vars)
    variable_to_dataframe(M[var], vars[var][:domain]...; value_name = value)
end




## Overall Welfare
description(M[:PC])
description(M[:PL])

#(PL/PC-1)*100

PC = var_to_df(M, :PC)
PL = var_to_df(M, :PL)

innerjoin(
        PC,
        PL,
        on = :region,
        renamecols = "" => "_wage"
    ) |>
    x -> transform(x,
        [:value, :value_wage] => ByRow((x,y) -> (y/x-1)*100) => :real_value
    ) |>
    x -> sort(x, :real_value) |>
    X -> plot(
        X, 
        x = :region, 
        y = :real_value, 
        color = :household, 
        type = :bar, 
        Layout(
            title = "Real wages", # I think this title is wrong
            #yaxis_range = [bounds[1,:min], bounds[1,:max]])
        )
    )