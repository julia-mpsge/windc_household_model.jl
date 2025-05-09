"""
    variable_to_dataframe(var::MPSGEIndexedVariable, columns::Symbol...; value_name = :value)
    variable_to_dataframe(var::MPSGEScalarVariable, columns::Symbol...; value_name = :value)

Converts a MPSGEIndexedVariable to a DataFrame. The resulting DataFrame will have
columns for each of the dimensions of the variable, as well as a column for the value
of the variable.

If the variable is a scalar variable, the resulting DataFrame will only have a column.
"""
function variable_to_dataframe(var::MPSGE.MPSGEIndexedVariable, columns::Symbol...; value_name::Symbol = :value)
    @assert length(columns) == length(axes(var)) "Number of columns must match the number of dimensions of the variable"

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
    x -> select(x, columns..., :value => value_name) 

    return df
end

function variable_to_dataframe(var::MPSGE.MPSGEScalarVariable, columns::Symbol...; value_name::Symbol = :value)
    @assert length(columns) == 0 "Number of columns must be 0 for scalar variables"

    df = DataFrame(
        value = [value(var)]
    ) |>
    x -> select(x, :value => value_name)

    return df

end