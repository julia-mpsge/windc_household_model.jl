# WiNDC Household Model

Add the package by running 

```julia
pkg> add https://github.com/julia-mpsge/windc_household_model.jl
```

It is also useful to add both `MPSGE` and `DataFrames` packages,

```julia
pkg> add MPSGE, DataFrames
```

Load and use the package by running

```julia
using windc_household_model

using DataFrames, MPSGE


data = load_data(2017)

M = household_model(data);

solve!(M, cumulative_iteration_limit=0)

zero_profit(M[:KS])

value(M[:ta]["AL", "ppd"])

set_value!(M[:ta]["AL", "ppd"], .5)

solve!(M)
```


```@autodocs
Modules = [windc_household_model]
Order   = [:function, :type]
```