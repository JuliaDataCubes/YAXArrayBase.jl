defaultfillval(T::Type{<:AbstractFloat}) = convert(T,1e32)
defaultfillval(::Type{Float16}) = Float16(3.2e4)
defaultfillval(T::Type{<:Integer}) = typemax(T)
defaultfillval(T::Type{<:AbstractString}) = ""

@require Zarr="0a941bbe-ad1d-11e8-39d9-ab76183a1d99" include("zarr.jl")

@require NetCDF="30363a11-5582-574a-97bb-aa9a979735b9" include("netcdf.jl")
