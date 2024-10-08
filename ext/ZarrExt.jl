module ZarrExt
  using YAXArrayBase
  using Zarr: ZArray, ZGroup, zgroup, zcreate, to_zarrtype, zopen, Compressor
  import YAXArrayBase: YAXArrayBase as YAB
  export ZarrDataset

  function __init__()
    @info "new driver key :zarr, updating backendlist."
    YAB.backendlist[:zarr] = ZarrDataset
    push!(YAB.backendregex, r"(.zarr$)|(.zarr/$)"=>ZarrDataset)
  end

  struct ZarrDataset
    g::ZGroup
  end
  ZarrDataset(g::String;mode="r") = ZarrDataset(zopen(g,mode,fill_as_missing=false))

  YAB.get_var_dims(ds::ZarrDataset,name) = reverse(ds[name].attrs["_ARRAY_DIMENSIONS"])
  YAB.get_varnames(ds::ZarrDataset) = collect(keys(ds.g.arrays))
  function YAB.get_var_attrs(ds::ZarrDataset, name) 
    #We add the fill value to the attributes to be consistent with NetCDF
    a = ds[name]
    if a.metadata.fill_value !== nothing
      merge(ds[name].attrs,Dict("_FillValue"=>a.metadata.fill_value))
    else
      ds[name].attrs
    end
  end
  YAB.get_global_attrs(ds::ZarrDataset) = ds.g.attrs
  Base.getindex(ds::ZarrDataset, i) = ds.g[i]
  Base.haskey(ds::ZarrDataset,k) = haskey(ds.g,k)

  # function add_var(p::ZarrDataset, T::Type{>:Missing}, varname, s, dimnames, attr; kwargs...)
  #   S = Base.nonmissingtype(T)
  #   add_var(p,S, varname, s, dimnames, attr; fill_value = defaultfillval(S), fill_as_missing=true, kwargs...)
  # end

  function YAB.add_var(p::ZarrDataset, T::Type, varname, s, dimnames, attr;
    chunksize=s, fill_as_missing=false, kwargs...)
    attr2 = merge(attr,Dict("_ARRAY_DIMENSIONS"=>reverse(collect(dimnames))))
    fv = get(attr,"_FillValue",get(attr,"missing_value",YAB.defaultfillval(T)))
    za = zcreate(T, p.g, varname,s...;fill_value = fv,fill_as_missing,attrs=attr2,chunks=chunksize,kwargs...)
    za
  end

  #Special case for init with Arrays
  function YAB.add_var(p::ZarrDataset, a::AbstractArray, varname, dimnames, attr;
    kwargs...)
    T = to_zarrtype(a)
    b = add_var(p,T,varname,size(a),dimnames,attr;kwargs...)
    b .= a
    a
  end

  YAB.create_empty(::Type{ZarrDataset}, path, gatts=Dict()) = ZarrDataset(zgroup(path, attrs=gatts))



  YAB.allow_parallel_write(::ZarrDataset) = true
  YAB.allow_missings(::ZarrDataset) = false
  YAB.to_dataset(g::ZGroup; kwargs...) = ZarrDataset(g)
  YAB.iscompressed(a::ZArray{<:Any,<:Any,<:Compressor}) = true

end