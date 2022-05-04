using .Zarr: ZArray, ZGroup, zgroup, zcreate,
to_zarrtype, zopen, Compressor

struct ZarrDataset
  g::ZGroup
end
ZarrDataset(g::String;mode="r") = ZarrDataset(zopen(g,mode))

get_var_dims(ds::ZarrDataset,name) = reverse(ds[name].attrs["_ARRAY_DIMENSIONS"])
get_varnames(ds::ZarrDataset) = collect(keys(ds.g.arrays))
get_var_attrs(ds::ZarrDataset, name) = ds[name].attrs
get_global_attrs(ds::ZarrDataset) = ds.g.attrs
Base.getindex(ds::ZarrDataset, i) = ds.g[i]
Base.haskey(ds::ZarrDataset,k) = haskey(ds.g,k)

function add_var(p::ZarrDataset, T::Type{>:Missing}, varname, s, dimnames, attr; kwargs...)
  S = Base.nonmissingtype(T)
  add_var(p,S, varname, s, dimnames, attr; fill_value = defaultfillval(S), kwargs...)
end

function add_var(p::ZarrDataset, T::Type, varname, s, dimnames, attr;
  chunksize=s, kwargs...)
  attr2 = merge(attr,Dict("_ARRAY_DIMENSIONS"=>reverse(collect(dimnames))))
  za = zcreate(T, p.g, varname,s...;attrs=attr2,chunks=chunksize,kwargs...)
  za
end

#Special case for init with Arrays
function add_var(p::ZarrDataset, a::AbstractArray, varname, dimnames, attr;
  kwargs...)
  T = to_zarrtype(a)
  b = add_var(p,T,varname,size(a),dimnames,attr;kwargs...)
  b .= a
  a
end

create_empty(::Type{ZarrDataset}, path, gatts=Dict()) = ZarrDataset(zgroup(path, attrs=gatts))

backendlist[:zarr] = ZarrDataset
push!(backendregex, r"(.zarr$)|(.zarr/$)"=>ZarrDataset)

allow_parallel_write(::ZarrDataset) = true
allow_missings(::ZarrDataset) = true
to_dataset(g::ZGroup; kwargs...) = ZarrDataset(g)
iscompressed(a::ZArray{<:Any,<:Any,<:Compressor}) = true