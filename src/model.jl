"""
    household_model(data)

Constructs a MPSGE model for the WiNDC household model. The model is constructed 
using the data provided by the [`load_data`](@ref) function.
"""
function household_model(data)
        
    TRN = String.(data["sets"]["trn"])
    G =  String.(data["sets"]["g"])
    GM = String.(data["sets"]["gm"])
    M =  String.(data["sets"]["m"])
    R =  String.(data["sets"]["r"])
    Q =  String.(data["sets"]["q"])
    H =  String.(data["sets"]["h"])
    S =  String.(data["sets"]["s"])

    a0 = data["parameters"]["a0"]
    c0_h = data["parameters"]["c0_h"]
    cd0_h = data["parameters"]["cd0_h"]
    dd0 = data["parameters"]["dd0"]
    dm0 = data["parameters"]["dm0"]
    esubL = data["parameters"]["esubL"]
    etaK = data["parameters"]["etaK"]
    fint0 = data["parameters"]["fint0"]
    fsav0 = data["parameters"]["fsav0"]
    g0 = data["parameters"]["g0"]
    govdef0 = data["parameters"]["govdef0"]
    hhtrn0 = data["parameters"]["hhtrn0"]
    i0 = data["parameters"]["i0"]
    id0 = data["parameters"]["id0"]
    kd0 = data["parameters"]["kd0"]
    ke0 = data["parameters"]["ke0"]
    ld0 = data["parameters"]["ld0"]
    le0 = data["parameters"]["le0"]
    ls0 = data["parameters"]["ls0"]
    lsr0 = data["parameters"]["lsr0"]
    m0 = data["parameters"]["m0"]
    md0 = data["parameters"]["md0"]
    nd0 = data["parameters"]["nd0"]
    nm0 = data["parameters"]["nm0"]
    rx0 = data["parameters"]["rx0"]
    s0 = data["parameters"]["s0"]
    sav0 = data["parameters"]["sav0"]
    ta0 = data["parameters"]["ta0"]
    tfica0 = data["parameters"]["tfica0"]
    tk0 = data["parameters"]["tk0"]
    tl_avg0 = data["parameters"]["tl_avg0"]
    tl0 = data["parameters"]["tl0"]
    tm0 = data["parameters"]["tm0"]
    totsav0 = data["parameters"]["totsav0"]
    trn0 = data["parameters"]["trn0"]
    ty0 = data["parameters"]["ty0"]
    x0 = data["parameters"]["x0"]
    xd0 = data["parameters"]["xd0"]
    xn0 = data["parameters"]["xn0"]
    yh0 = data["parameters"]["yh0"]
    ys0 = data["parameters"]["ys0"]




    HH = MPSGEModel()

    @parameters(HH, begin
        ta[R,G], 0, (description = "Consumption Tax")
        ty[R,S], 0, (description = "Production Tax")
        tm[R,G], 0, (description = "Import Tax")
        tk[R,S], 0, (description = "Capital Tax")
        tfica[R,H], 0, (description = "FICA Labor Shares")
        tl[R,H], 0, (description = "Marginal Labor Tax")
    end)

    for r∈R, g∈G
        set_value!(ta[r,g], ta0[r,g])
        set_value!(ty[r,g], ty0[r,g])
        set_value!(tm[r,g], tm0[r,g])
        set_value!(tk[r,g], tk0[r])
    end

    for r∈R,h∈H
        set_value!(tfica[r,h], tfica0[r,h])
        set_value!(tl[r,h], tl0[r,h])
    end

    @sectors(HH, begin
        Y[R,S], (description = "Production")
        X[R,G], (description = "Disposition")
        A[R,G], (description = "Absorption")
        LS[R,H], (description = "Labor Supply")
        KS, (description = "Aggregate Capital Stock")
        C[R,H], (description = "Household Consumption")
        MS[R,M], (description = "Margin Supply")
        INVEST_DEMAND
        GOVT_DEMAND
    end)

    @commodities(HH, begin
        PA[R,G], (description = "Regional Market (input)")
        PY[R,G], (description = "Regional Market (output)")
        PD[R,G], (description = "Local Market Price")
        RK[R,S], (description = "Sectoral Rental Rate")
        RKS, (description = "Capital Stock")
        PM[R,M], (description = "Margin Price")
        PC[R,H], (description = "Consumer Price Index")
        PN[G], (description = "National Market Price for goods")
        PLS[R,H], (description = "Leisure Price")
        PL[R], (description = "Regional Wage Rate")
        PK, (description = "Aggregate return to capital")
        PFX, (description = "Foreign Exchange Rate")
        INVEST_COMMODITY
        GOVT_COMMODITY
    end)

    @consumers(HH, begin
        RA[R,H], (description = "Representative Agent")
        NYSE, (description = "Aggregate Capital Owner")
        INVEST, (description = "Aggregate Investor")
        GOVT, (description = "Aggregate Government")
        #ROW # if fint0 !=0
    end)

    @auxiliaries(HH, begin
        SAVRATE, (description = "Domestic Savings Rate")
        TRANS, (description = "Budget balance rationing variable")
        SSK, (description = "Steady-state capital stock")
        CPI, (description = "Consumer Price Index")
    end)

    set_start_value(SAVRATE, 1)
    set_start_value(TRANS, 1)
    set_start_value(SSK, 1)
    set_start_value(CPI, 1)

    for r∈R,ŝ∈S
        @production(HH, Y[r,ŝ], [t=0, s=0, va=>s=1], begin
            [@output(PY[r,g], ys0[r,ŝ,g], t, taxes = [Tax(GOVT, ty[r,ŝ])], reference_price = 1-ty0[r,ŝ]) for g∈G]...
            [@input(PA[r,g], id0[r,g,ŝ], s) for g∈G]...
            @input(PL[r], ld0[r,ŝ], va)
            @input(RK[r,ŝ], kd0[r,ŝ], va, taxes=[Tax(GOVT, tk[r,ŝ])], reference_price = 1+tk0[r])
        end)
    end

    for r∈R,g∈G
        @production(HH, X[r,g], [t=4, s=1], begin
            @output(PFX, x0[r,g] - rx0[r,g], t)
            @output(PN[g], xn0[r,g], t)
            @output(PD[r,g], xd0[r,g], t)
            @input(PY[r,g], s0[r,g], s)
        end)
    end

    for r∈R, g∈G
        @production(HH, A[r,g], [t=0, s=0, dm=>s=4, d=>dm=2], begin
            @output(PA[r,g], a0[r,g], t, taxes = [Tax(GOVT, ta[r,g])], reference_price = 1-ta0[r,g])
            @output(PFX, rx0[r,g], t)
            @input(PN[g], nd0[r,g], d)
            @input(PD[r,g], dd0[r,g], d)
            @input(PFX, m0[r,g], dm, taxes = [Tax(GOVT, tm[r,g])], reference_price = 1+tm0[r,g])
            [@input(PM[r,m], md0[r,m,g], s) for m∈M]...
        end)
    end

    for r∈R, m∈M
        @production(HH, MS[r,m], [t=0, s=0], begin
            @output(PM[r,m], sum(md0[r,m,gm] for gm∈GM), t)
            [@input(PN[gm], nm0[r,gm,m], s) for gm∈GM]...
            [@input(PD[r,gm], dm0[r,gm,m], s) for gm∈GM]...
        end)
    end

    for r∈R,h∈H
        @production(HH, C[r,h], [t=0, s=1], begin
            @output(PC[r,h], c0_h[r,h], t)
            [@input(PA[r,g], cd0_h[r,g,h], s) for g∈G]...
        end)
    end

    for r∈R, h∈H
        @production(HH, LS[r,h], [t=0, s=1], begin
            [@output(PL[q], le0[r,q,h], t, taxes=[Tax(GOVT, tl[r,h] + tfica[r,h])], reference_price = 1-tl0[r,h]-tfica0[r,h]) for q∈Q]...
            @input(PLS[r,h], ls0[r,h], s)
        end)
    end

    @production(HH, KS, [t=etaK, s=1], begin
        [@output(RK[r,s], kd0[r,s], t) for r∈R, s∈S]...
        @input(RKS, sum(kd0[r,s] for r∈R, s∈S), s)
    end)


    for r∈R,h∈H
        @demand(HH, RA[r,h], begin
            @final_demand(PC[r,h], c0_h[r,h])
            @final_demand(PLS[r,h], lsr0[r,h])
            @endowment(PLS[r,h], ls0[r,h]+lsr0[r,h])
            @endowment(PFX, TRANS*sum(hhtrn0[r,h,trn] for trn∈TRN))
            @endowment(PLS[r,h], (tl[r,h] - tl_avg0[r,h])*sum(le0[r,q,h] for q∈Q))
            @endowment(PK, ke0[r,h])
            @endowment(PFX, -sav0[r,h]*SAVRATE)
        end, elasticity = esubL[r,h])
    end



    @demand(HH, NYSE, begin
        @final_demand(PK, sum(yh0[r,g] for r∈R, g∈G)+ sum(kd0[r,s] for r∈R, s∈S)*SSK)#)
        [@endowment(PY[r,g], yh0[r,g]) for r∈R, g∈G]...
        @endowment(RKS, SSK*sum(kd0[r,s] for r∈R, s∈S))
    end)


    @production(HH, INVEST_DEMAND, [t=0, s=0], begin
        @output(INVEST_COMMODITY, sum(i0[r,g] for r∈R, g∈G), t)
        [@input(PA[r,g], i0[r,g], s) for r∈R, g∈G]...
    end)

    @demand(HH, INVEST, begin
        #[@final_demand(PA[r,g], i0[r,g]) for r∈R, g∈G]...
        @final_demand(INVEST_COMMODITY, sum(i0[r,g] for r∈R, g∈G))
        @endowment(PFX, totsav0*SAVRATE)
        @endowment(PFX, fsav0)
    end)#, elasticity = 0)


    @production(HH, GOVT_DEMAND, [t=0, s= 1], begin
        @output(GOVT_COMMODITY, sum(g0[r,g] for r∈R,g∈G), t)
        [@input(PA[r,g], g0[r,g], s) for r∈R, g∈G]...

    end)    



    @demand(HH, GOVT, begin
        #[@final_demand(PA[r,g], g0[r,g]) for r∈R, g∈G]...
        @final_demand(GOVT_COMMODITY, sum(g0[r,g] for r∈R,g∈G))
        @endowment(PFX, -TRANS*sum(trn0[r,h] for r∈R, h∈H))
        @endowment(PFX, govdef0)
        [@endowment(PLS[r,h], -(tl[r,h] - tl_avg0[r,h])*sum(le0[r,q,h] for q∈Q)) for r∈R, h∈H]...
    end)


    #@demand(HH, ROW, begin
    #    @final_demand(PFX, fint0)
    #    @endowment(PK, fint0)
    #end)

    @aux_constraint(HH, SSK,
        sum(i0[r,g]*PA[r,g] for r∈R, g∈G) - sum(i0[r,g] for r∈R, g∈G) *RKS
    )

    @aux_constraint(HH, SAVRATE,
        INVEST - sum(PA[r,g]*i0[r,g] for r∈R, g∈G)*SSK
    )

    @aux_constraint(HH, TRANS,
        GOVT - sum(PA[r,g]*g0[r,g] for r∈R, g∈G)
    )

    @aux_constraint(HH, CPI, 
        CPI - sum(PC[r,h]*c0_h[r,h] for r∈R, h∈H)/sum(c0_h[r,h] for r∈R, h∈H)
    )


    return HH
end