module gpuPixelDoublets
    using StaticArrays
    include("ca_constants.jl")
    using .caConstants
    n_pairs = 13 + 2 + 4 
    const layer_pairs = SArray{Tuple{2*n_pairs}}(
        0, 1, 0, 4, 0, 7,              # BPIX1 (3)
        1, 2, 1, 4, 1, 7,              # BPIX2 (5)
        4, 5, 7, 8,                    # FPIX1 (8)
        2, 3, 2, 4, 2, 7, 5, 6, 8, 9,  # BPIX3 & FPIX2 (13)
        0, 2, 1, 3,                    # Jumping Barrel (15)
        0, 5, 0, 8,                    # Jumping Forward (BPIX1,FPIX2)
        4, 6, 7, 9                     # Jumping Forward (19)
    )
    const phi0p05::Int16 = 522 #round(521.52189...) = phi2short(0.05);
    const phi0p06::Int16 = 626 #round(625.82270...) = phi2short(0.06);
    const phi0p07::Int16 = 730 #round(730.12648...) = phi2short(0.07);
    const phi_cuts = SArray{Tuple{n_pairs}}(
        phi0p05,
        phi0p07,
        phi0p07,
        phi0p05,
        phi0p06,
        phi0p06,
        phi0p05,
        phi0p05,
        phi0p06,
        phi0p06,
        phi0p06,
        phi0p05,
        phi0p05,
        phi0p05,
        phi0p05,
        phi0p05,
        phi0p05,
        phi0p05,
        phi0p05
    )

    const minz = SArray{Tuple{n_pairs}}(-20., 0., -30., -22., 10., -30., -70., -70., -22., 15., -30, -70., -70., -20., -22., 0, -30., -70., -70.)
    const maxz = SArray{Tuple{n_pairs}}(20., 30., 0., 22., 30., -10., 70., 70., 22., 30., -15., 70., 70., 20., 22., 30., 0., 70., 70.)
    const maxr = SArray{Tuple{n_pairs}}(20., 9., 9., 20., 7., 7., 5., 5., 20., 6., 6., 5., 5., 20., 20., 9., 9., 9., 9.)

end