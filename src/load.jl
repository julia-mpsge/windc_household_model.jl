"""
    load_data(year::Int)

Load the household data for a given year. Only the years 2017 and 2021 are available.
"""
function load_data(year::Int)
    @assert year∈[2017,2021] "Only the years 2017 and 2021 are available"

    data = load(joinpath(@__DIR__, "..", "data", "data_$year.jld2"))

    return data
end