using .NetCDF

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
end
NetCDFDataset(filename;mode="r") = mode == "r" ? NetCDFDataset(filename,NC_NOWRITE) : NetCDFDataset(filename,NC_WRITE)

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
writeblock!(v::NetCDFVariable, aout, r::AbstractUnitRange...) = NetCDF.open(a->writeblock!(a,aout,r...), v.filename, v.varname, mode=NC_WRITE)
readblock!(v::NetCDFVariable, aout, r::AbstractUnitRange...) = NetCDF.open(a->readblock!(a,aout,r...), v.filename, v.varname)
iscompressed(v::NetCDFVariable) = NetCDF.open(v->v.compress > 0, v.filename, v.varname)

Base.size(v::NetCDFVariable) = v.size

get_var_dims(ds::NetCDFDataset,name) = NetCDF.open(v->map(i->i.name,v[name].dim),ds.filename)
get_varnames(ds::NetCDFDataset) = NetCDF.open(v->collect(keys(v.vars)),ds.filename)
get_var_attrs(ds::NetCDFDataset, name) = NetCDF.open(v->v[name].atts,ds.filename)
get_global_attrs(ds::NetCDFDataset) = NetCDF.open(nc->nc.gatts, ds.filename)
function Base.getindex(ds::NetCDFDataset, i)
  s,et = NetCDF.open(j->(size(j),eltype(j)),ds.filename,i)
  NetCDFVariable{et,length(s)}(ds.filename, i, s)
end
Base.haskey(ds::NetCDFDataset,k) = NetCDF.open(nc->haskey(nc.vars,k),ds.filename)

function add_var(p::NetCDFDataset, T::Type, varname, s, dimnames, attr;
  chunksize=s, compress = -1)
  dimsdescr = Iterators.flatten(zip(dimnames,s))
  nccreate(p.filename, varname, dimsdescr..., atts = attr, t=T, chunksize=chunksize, compress=compress)
  NetCDFVariable{T,length(s)}(p.filename,varname,(s...,))
end

function create_empty(::Type{NetCDFDataset}, path, gatts=Dict())
  NetCDF.create(_->nothing, path, NcVar[], gatts = gatts)
  NetCDFDataset(path)
end

allow_parallel_write(::Type{<:NetCDFDataset}) = false
allow_parallel_write(::NetCDFDataset) = false

allow_missings(::Type{<:NetCDFDataset}) = false
allow_missings(::NetCDFDataset) = false

backendlist[:netcdf] = NetCDFDataset
push!(backendregex,r".nc$"=>NetCDFDataset)
