using CSV
using DataFrames
using JSON
using NamedArrays
using FileIO

domain = JSON.parsefile("WiNDC_household/domain.json")

set_dir = "WiNDC_household/data_2017/sets/"


all_sets = Dict()
for s in readdir(set_dir)
    S = CSV.read(set_dir * s, DataFrame)
    all_sets[split(s,".")[1]] = S[!,1]
end

all_sets



all_parameters = Dict()
for (parm,D) in domain

    if parm != "yh0" && length(D) > 1
        #println(parm)
        df = CSV.read("WiNDC_household/data_2017/parameters/$(parm).csv", DataFrame)
        dd = [String.(all_sets[d]) for d∈D]
        all_parameters[parm] = NamedArray(zeros(length.(dd)...), dd, D)
        for row in eachrow(df)
            all_parameters[parm][[String(row[d]) for d∈D]...] = row[:value]
        end
    elseif length(D) == 1
        df = CSV.read("WiNDC_household/data_2017/parameters/$(parm).csv", DataFrame)
        dd = [String.(all_sets[d]) for d∈D]
        all_parameters[parm] = NamedArray(zeros(length.(dd)...), (dd...), (D...))
        for row in eachrow(df)
            all_parameters[parm][[String(row[d]) for d∈D]...] = row[:value]
        end
    elseif length(D) == 0
        df = CSV.read("WiNDC_household/data_2017/parameters/$(parm).csv", DataFrame)
        all_parameters[parm] = df[1,1]
    elseif parm == "yh0"
        dd = [String.(all_sets[d]) for d∈D]
        all_parameters[parm] = NamedArray(zeros(length.(dd)...), dd, D)
    else
        println(parm)
    end
end


all_parameters

data = Dict()
data["sets"] = all_sets
data["parameters"] = all_parameters

save("WiNDC_household/data.jld2", data)