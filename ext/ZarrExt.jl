module ZarrExt
using YAXArrayBase
using Zarr: ZArray, ZGroup, zgroup, zcreate, to_zarrtype, zopen, Compressor, ZipStore
import DiskArrays: AbstractDiskArray, DiskArrays, Unchunked, Chunked, GridChunks
using ZipArchives: ZipReader
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
function ZarrDataset(g::String; mode="r")
  store = if endswith(g, "zip")
    ZipStore(ZipReader(SimpleFileDiskArray(g)))
  else
    g
  end
  ZarrDataset(zopen(store, mode, fill_as_missing=false))
end

YAB.get_var_dims(ds::ZarrDataset, name) = reverse(ds[name].attrs["_ARRAY_DIMENSIONS"])
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
  chunksize=s, fill_as_missing=false, kwargs...)
  attr2 = merge(attr, Dict("_ARRAY_DIMENSIONS" => reverse(collect(dimnames))))
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
  T = to_zarrtype(a)
  b = add_var(p, T, varname, size(a), dimnames, attr; kwargs...)
  b .= a
  a
end

YAB.create_empty(::Type{ZarrDataset}, path, gatts=Dict()) = ZarrDataset(zgroup(path, attrs=gatts))



YAB.allow_parallel_write(::ZarrDataset) = true
YAB.allow_missings(::ZarrDataset) = false
YAB.to_dataset(g::ZGroup; kwargs...) = ZarrDataset(g)
YAB.iscompressed(a::ZArray{<:Any,<:Any,<:Compressor}) = true


#Add ability to read zipped zarrs


struct SimpleFileDiskArray{C<:Union{Int,Nothing}} <: AbstractDiskArray{UInt8,1}
  file::String
  s::Int
  chunksize::C
end
Base.size(s::SimpleFileDiskArray) = (s.s,)
function SimpleFileDiskArray(filename; chunksize=nothing)
  isfile(filename) || throw(ArgumentError("File $filename does not exist"))
  s = filesize(filename)
  SimpleFileDiskArray(filename, s, chunksize)
end
function DiskArrays.readblock!(a::SimpleFileDiskArray, aout, i::AbstractUnitRange)
  open(a.file) do f
    seek(f, first(i) - 1)
    read!(f, aout)
  end
end
DiskArrays.haschunks(a::SimpleFileDiskArray) = a.chunksize === nothing ? Unchunked() : Chunked()
function DiskArrays.eachchunk(a::SimpleFileDiskArray)
  if a.chunksize === nothing
    DiskArrays.estimate_chunksize(a)
  else
    GridChunks((a.s,), (a.chunksize,))
  end
end



end