module NetCDFExt
import YAXArrayBase: YAXArrayBase as YAB
using NetCDF

"""
    NetCDFDataset

Dataset backend to read NetCDF files using NetCDF.jl

The following keyword arguments are allowed when using :netcdf
as a data sink:

- `compress = -1` set the compression level for the NetCDF file
"""
struct NetCDFDataset
  filename::String
  mode::UInt16
  handle::Base.RefValue{Union{Nothing, NcFile}}
end
function NetCDFDataset(filename;mode="r") 
  m = mode == "r" ? NC_NOWRITE : NC_WRITE
  NetCDFDataset(filename,m,Ref{Union{Nothing, NcFile}}(nothing)) 
end
function dsopen(f,ds::NetCDFDataset)
  if ds.handle[] === nothing
    NetCDF.open(f, ds.filename)
  else
    f(ds.handle[])
  end
end
function YAB.open_dataset_handle(f, ds::NetCDFDataset)
  if ds.handle[] === nothing
    try
      ds.handle[] = NetCDF.open(ds.filename, mode=ds.mode)
      f(ds)
    finally
      ds.handle[]=nothing
    end
  else
    f(ds)
  end
end



import .NetCDF: AbstractDiskArray, readblock!, writeblock!, haschunks, eachchunk

struct NetCDFVariable{T,N} <: AbstractDiskArray{T,N}
  filename::String
  varname::String
  size::NTuple{N,Int}
end
#Define method forwarding for DiskArray methods
for m in [:haschunks, :eachchunk]
  eval(:(function $(m)(v::NetCDFVariable,args...;kwargs...)
    NetCDF.open(a->$(m)(a,args...;kwargs...), v.filename, v.varname)
end
))
end
function check_contig(x)
   isa(x,Array) || (isa(x,SubArray) && Base.iscontiguous(x))
end
writeblock!(v::NetCDFVariable, aout, r::AbstractUnitRange...) = NetCDF.open(a->writeblock!(a,aout,r...), v.filename, v.varname, mode=NC_WRITE)
function readblock!(v::NetCDFVariable, aout, r::AbstractUnitRange...) 
  if check_contig(aout)
    NetCDF.open(a->readblock!(a,aout,r...), v.filename, v.varname)
  else
    aouttemp = Array(aout)
    NetCDF.open(a->readblock!(a,aouttemp,r...), v.filename, v.varname)
    aout .= aouttemp
  end
end
YAB.iscompressed(v::NetCDFVariable) = NetCDF.open(v->v.compress > 0, v.filename, v.varname)

Base.size(v::NetCDFVariable) = v.size

YAB.get_var_dims(ds::NetCDFDataset,name) = dsopen(v->map(i->i.name,v[name].dim),ds)
YAB.get_varnames(ds::NetCDFDataset) = dsopen(v->collect(keys(v.vars)),ds)
YAB.get_var_attrs(ds::NetCDFDataset, name) = dsopen(v->v[name].atts,ds)
YAB.get_global_attrs(ds::NetCDFDataset) = dsopen(nc->nc.gatts, ds)
function YAB.get_var_handle(ds::NetCDFDataset, i; persist = true)
  if persist || ds.handle[] === nothing
    s,et = NetCDF.open(j->(size(j),eltype(j)),ds.filename,i)
    NetCDFVariable{et,length(s)}(ds.filename, i, s)
  else
    ds.handle[][i]
  end
end
Base.haskey(ds::NetCDFDataset,k) = dsopen(nc->haskey(nc.vars,k),ds)

function YAB.add_var(p::NetCDFDataset, T::Type, varname, s, dimnames, attr;
  chunksize=s, compress = -1)
  dimsdescr = Iterators.flatten(zip(dimnames,s))
  nccreate(p.filename, varname, dimsdescr..., atts = attr, t=T, chunksize=chunksize, compress=compress)
  NetCDFVariable{T,length(s)}(p.filename,varname,(s...,))
end

function YAB.create_empty(::Type{NetCDFDataset}, path, gatts=Dict())
  NetCDF.create(_->nothing, path, NcVar[], gatts = gatts)
  NetCDFDataset(path)
end

YAB.allow_parallel_write(::Type{<:NetCDFDataset}) = false
YAB.allow_parallel_write(::NetCDFDataset) = false

YAB.allow_missings(::Type{<:NetCDFDataset}) = false
YAB.allow_missings(::NetCDFDataset) = false

function __init__()
  @debug "new driver key :netcdf, updating backendlist."
  YAB.backendlist[:netcdf] = NetCDFDataset
  push!(YAB.backendregex,r".nc$"=>NetCDFDataset)
end

end