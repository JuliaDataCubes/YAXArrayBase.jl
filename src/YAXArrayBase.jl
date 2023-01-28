module YAXArrayBase

  using DataStructures: OrderedDict

include("datasets/datasetinterface.jl")
include("axisarrays/axisinterface.jl")
include("axisarrays/namedtuple.jl")

defaultfillval(T::Type{<:AbstractFloat}) = convert(T,1e32)
defaultfillval(::Type{Float16}) = Float16(3.2e4)
defaultfillval(T::Type{<:Integer}) = typemax(T)
defaultfillval(T::Type{<:AbstractString}) = ""

function __init__()
  """
  YAXArrayBase.backendlist

  List of symbols defining dataset backends.
  """
  backendlist = OrderedDict{Symbol, Any}(
    :array => Array,
  )

  backendregex = Pair[]
end


export dimvals, dimname, dimnames, iscontdim, iscompressed,
getattributes, getdata, yaxconvert
export get_var_handle, get_varnames, get_var_dims, get_var_attrs,
create_empty, add_var, allow_parallel_write,
to_dataset, allow_missings
end # module
