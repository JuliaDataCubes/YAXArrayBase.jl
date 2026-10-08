module ZarrCoreExt
using YAXArrayBase
using ZarrCore: ZarrCore, ZArray, ZGroup, zgroup, zcreate, zopen, NoCompressor, CRC32cV3Codec
import YAXArrayBase: YAXArrayBase as YAB
export ZarrDataset

function __init__()
  @debug "new driver key :zarr, updating backendlist."
  YAB.backendlist[:zarr] = ZarrDataset
  push!(YAB.backendregex, r"(.zarr$)|(.zarr/$)|(zarr.zip$)" => ZarrDataset)
end

struct ZarrDataset
  g::ZGroup
end
function ZarrDataset(g::Union{String,ZGroup}; mode="r", path="", kwargs...)
  if g isa ZGroup
    return ZarrDataset(g)
  end
  store = if endswith(g, "zip")
    YAB.zarr_zipstore(g)
  else
    g
  end
  ZarrDataset(zopen(store, mode, fill_as_missing=false, path=path))
end

function YAB.get_var_dims(ds::ZarrDataset, name)
  a = ds[name]
  # Zarr v3 stores dimension names in the array metadata, already in Julia order
  dn = ZarrCore.dimension_names(a)
  if dn !== nothing && all(!isnothing, dn)
    return collect(String, dn)
  end
  haskey(a.attrs, "_ARRAY_DIMENSIONS") || throw(ArgumentError("Zarr array $name has no dimension names"))
  reverse(a.attrs["_ARRAY_DIMENSIONS"])
end
YAB.get_varnames(ds::ZarrDataset) = collect(keys(ds.g.arrays))
function YAB.get_var_attrs(ds::ZarrDataset, name)
  #We add the fill value to the attributes to be consistent with NetCDF
  a = ds[name]
  if a.metadata.fill_value !== nothing
    merge(ds[name].attrs, Dict("_FillValue" => a.metadata.fill_value))
  else
    ds[name].attrs
  end
end
YAB.get_global_attrs(ds::ZarrDataset) = ds.g.attrs
Base.getindex(ds::ZarrDataset, i) = ds.g[i]
Base.haskey(ds::ZarrDataset, k) = haskey(ds.g, k)

# function add_var(p::ZarrDataset, T::Type{>:Missing}, varname, s, dimnames, attr; kwargs...)
#   S = Base.nonmissingtype(T)
#   add_var(p,S, varname, s, dimnames, attr; fill_value = defaultfillval(S), fill_as_missing=true, kwargs...)
# end

function YAB.add_var(p::ZarrDataset, T::Type, varname, s, dimnames, attr;
  chunksize=s, fill_as_missing=false, zarr_format=nothing, kwargs...)
  # The format is set by the group in create_empty
  if zarr_format !== nothing && zarr_format != _zarr_format(p)
    throw(ArgumentError("Can not create a Zarr v$zarr_format array in a Zarr v$(_zarr_format(p)) group"))
  end
  if !haskey(kwargs, :compressor) && ZarrCore.default_compressor() isa NoCompressor
    @info "No Zarr compressor package is loaded, so data will be written uncompressed. Load e.g. ZarrBlosc or Zarr to enable compression." maxlog = 1
  end
  if _zarr_format(p) == 2
    attr2 = merge(attr, Dict("_ARRAY_DIMENSIONS" => reverse(collect(String, dimnames))))
  else
    attr2 = attr
    kwargs = (; kwargs..., dimension_names=Tuple(collect(String, dimnames)))
  end
  fv = get(attr, "_FillValue", get(attr, "missing_value", YAB.defaultfillval(T)))
  attr3 = filter(attr2) do (k, v)
    !isa(v, AbstractFloat) || !isnan(v)
  end
  za = zcreate(T, p.g, varname, s...; fill_value=fv, fill_as_missing, attrs=attr3, chunks=chunksize, kwargs...)
  za
end

#Special case for init with Arrays
function YAB.add_var(p::ZarrDataset, a::AbstractArray, varname, dimnames, attr;
  kwargs...)
  # to_zarrtype is not public in ZarrCore
  T = ZarrCore.to_zarrtype(a)
  b = add_var(p, T, varname, size(a), dimnames, attr; kwargs...)
  b .= a
  a
end

YAB.create_empty(::Type{ZarrDataset}, path, gatts=Dict(); zarr_format=2, kwargs...) =
  ZarrDataset(zgroup(ZarrCore.storefromstring(path, true)..., zarr_format; attrs=gatts))
_zarr_format(ds::ZarrDataset) = _zarr_format(ds.g.zarr_format)
_zarr_format(::ZarrCore.ZarrFormat{N}) where N = N



YAB.allow_parallel_write(::ZarrDataset) = true
YAB.allow_missings(::ZarrDataset) = false
YAB.to_dataset(g::ZGroup; kwargs...) = ZarrDataset(g; kwargs...)
# get_pipeline, V2Pipeline and V3Pipeline are not public in ZarrCore
YAB.iscompressed(a::ZArray) = _iscompressed(ZarrCore.get_pipeline(a.metadata))
_iscompressed(p::ZarrCore.V2Pipeline) = !isa(p.compressor, NoCompressor)
# Checksum codecs are bytes-to-bytes codecs too, but do not compress
_iscompressed(p::ZarrCore.V3Pipeline) = any(c -> !isa(c, CRC32cV3Codec), p.bytes_bytes)

end
