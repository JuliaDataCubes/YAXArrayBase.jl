#Functions to be implemented for Dataset sources:
"Return a DiskArray handle to a dataset"
get_var_handle(ds, name) = ds[name]

"Return a list of variable names"
function get_varnames(ds) end

"Return a list of dimension names for a given variable"
function get_var_dims(ds, name) end

"Return a dict with the attributes for a given variable"
function get_var_attrs(ds,name) end


#Functions to be implemented for Dataset sinks
"Initialize and return a handle to a new empty dataset"
create_empty(T::Type,path) =
  error("create_empty not implemented for $T")

"""
    add_var(ds, T, name, s, dimlist, atts)

Add a new variable to the dataset with element type `T`,
name `name`, size `s` and depending on the dimensions `dimlist`
given by a list of Strings. `atts` is a list of attributes.
"""
function add_var(ds, T, name, s, dimlist, atts;kwargs...) end

"""
    allow_parallel_write(ds)

Returns true if different chunks of a dataset can be written to by
2 processes simultaneously
"""
allow_parallel_write(ds) = false

allow_missings(ds) = true

#Fallback for writing array
function add_var(ds,x::AbstractArray,name,s,dimlist,atts;kwargs...)
  a = add_var(ds,eltype(x),name,s,dimlist,atts;kwargs...)
  if ds isa NetCDFDataset
    sleep(0.1)
  end
  a .= x
  a
end

using DataStructures: OrderedDict
backendlist = OrderedDict{Symbol, Any}(
  :array => Array,
)

backendregex = Pair[]

function to_dataset(g::String; driver=:all)
  if driver == :all
    for p in YAXArrayBase.backendregex
      if match(p[1],g) !== nothing
        return to_dataset(p[2],g)
      end
    end
    return to_dataset(g,driver=:zarr)
  else
    return to_dataset(backendlist[driver],g)
  end
end
to_dataset(g; kwargs...) = g
to_dataset(T::Type{<:Any}, g::String) = T(g)
