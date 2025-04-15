struct HisToContainer{T,N_BINS,SIZE,S,I,N_HISTS,U <: AbstractArray{UInt32},V <: AbstractArray{I}} # T is the type of discretized input values, NBINS is the number of bins, size is the maximum number of elements in bins, 
    off::U # goes from bin 1 to bin N_BINS*N_HISTS + 1 
    bins::V # holds indices to the values placed within a certain bin that are of type I. Indices for bins range from 1 to SIZE
    psws::Int32 # prefix scan working place
    
end
function kernel()
    hist = HisToContainer{UInt32,10,10,1,UInt16,1,CuDeviceArray{UInt32,1,AS.Shared},CuDeviceArray{UInt16,1,AS.Shared}}
    h = @cuStaticSharedMem(hist,1)
    h[1] = hist()
    h2 = @cuStaticSharedMem(UInt32,32)
    @cuprintln(h2[10])
    return
end

@cuda threads = 1 kernel()
