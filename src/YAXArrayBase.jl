module YAXArrayBase
using Requires: @require

include("datasets/datasetinterface.jl")
include("axisarrays/axisinterface.jl")

function __init__()
  include(joinpath(@__DIR__,"datasets/datasetimpl.jl"))
  include(joinpath(@__DIR__,"axisarrays/axisarrayimpl.jl"))
end


export dimvals, dimname, dimnames, iscontdim, iscompressed,
getattributes, getdata, yaxconvert
export get_var_handle, get_varnames, get_var_dims, get_var_attrs,
create_empty, add_var, allow_parallel_write,
to_dataset, allow_missings
end # module
