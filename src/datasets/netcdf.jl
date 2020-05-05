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
NetCDFDataset(filename) = NetCDFDataset(filename,NC_NOWRITE)

get_var_dims(ds::NetCDFDataset,name) = NetCDF.open(v->map(i->i.name,v[name].dim),ds.filename)
get_varnames(ds::NetCDFDataset) = NetCDF.open(v->collect(keys(v.vars)),ds.filename)
get_var_attrs(ds::NetCDFDataset, name) = NetCDF.open(v->v[name].atts,ds.filename)
function Base.getindex(ds::NetCDFDataset, i)
  NetCDF.open(ds.filename,i,mode=ds.mode)
end
Base.haskey(ds::NetCDFDataset,k) = NetCDF.open(nc->haskey(nc.vars,k),ds.filename)

function add_var(p::NetCDFDataset, T::Type, varname, s, dimnames, attr;
  chunksize=s, compress = -1)
  dimsdescr = Iterators.flatten(zip(dimnames,s))
  nccreate(p.filename, varname, dimsdescr..., atts = attr, t=T, chunksize=chunksize, compress=compress)
  NetCDF.open(p.filename,varname,mode=p.mode)
end

function create_empty(::Type{NetCDFDataset}, path)
  NetCDF.create(path, NcVar[])
  NetCDFDataset(path,NC_WRITE)
end

allow_parallel_write(::NetCDFDataset) = false

allow_missings(::NetCDFDataset) = false

backendlist[:netcdf] = NetCDFDataset
push!(backendregex,r".nc$"=>NetCDFDataset)
