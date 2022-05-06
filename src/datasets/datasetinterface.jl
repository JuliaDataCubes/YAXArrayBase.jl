#Functions to be implemented for Dataset sources:
"Return a DiskArray handle to a dataset"
get_var_handle(ds, name) = ds[name]

"Return a list of variable names"
function get_varnames end

"Return a list of dimension names for a given variable"
function get_var_dims end

"Return a dict with the attributes for a given variable"
function get_var_attrs end

"Return a dict with global attributes for the dataset"
function get_global_attrs end

#Functions to be implemented for Dataset sinks
"Initialize and return a handle to a new empty dataset"
function create_empty end

"""
    add_var(ds, T, name, s, dimlist, atts)

Add a new variable to the dataset with element type `T`,
name `name`, size `s` and depending on the dimensions `dimlist`
given by a list of Strings. `atts` is a Dict with attributes.
"""
function add_var end

"""
    allow_parallel_write(ds)

Returns true if different chunks of a dataset can be written to by
2 processes simultaneously
"""
allow_parallel_write(ds) = false

"""
    allow_missings(ds)

Returns true if Union{T,Missing} is an allowed data type for the backend
and if an array containing missings can be written to the array.
"""
allow_missings(ds) = true

#Fallback for writing array
function add_var(ds,x::AbstractArray,name,dimlist,atts;kwargs...)
  a = add_var(ds,eltype(x),name,size(x),dimlist,atts;kwargs...)
  a .= x
  a
end

function create_dataset(T::Type, path, gatts, dimnames, dimvals, dimattrs, vartypes, varnames, vardims, varattrs, varchunks; kwargs...)
  ds = create_empty(T, path, gatts)
  axlengths = Dict{String, Int}()
  for (dname, dval, dattr) in zip(dimnames, dimvals, dimattrs)
    add_var(ds, dval, dname, (dname,), dattr)
    axlengths[dname] = length(dval)
  end
  for (T, vn, vd, va, vc) in zip(vartypes, varnames, vardims, varattrs, varchunks)
    s = getindex.(Ref(axlengths),vd) 
    add_var(ds, T, vn, (s...,), vd, va; chunksize = vc, kwargs...)
  end
  ds
end

using DataStructures: OrderedDict
"""
    YAXArrayBase.backendlist

List of symbols defining dataset backends.
"""
backendlist = OrderedDict{Symbol, Any}(
  :array => Array,
)

backendregex = Pair[]

function backendfrompath(g::String; driver = :all)
  if driver == :all
    for p in YAXArrayBase.backendregex
      if match(p[1],g) !== nothing
        return p[2]
      end
    end
    return last(first(backendregex))
  else
    return backendlist[driver]
  end
end

to_dataset(g::String; driver=:all, kwargs...) = to_dataset(backendfrompath(g;driver),g,kwargs...)

to_dataset(g; kwargs...) = g
to_dataset(T::Type{<:Any}, g::String;kwargs...) = T(g;kwargs...)
