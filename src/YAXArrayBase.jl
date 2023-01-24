module YAXArrayBase
#if !isdefined(Base, :get_extension)
#  using Requires
#end
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
  #=
@static if !isdefined(Base, :get_extension)
  @require NamedDims="356022a1-0364-5f58-8944-0da4b18d706f" include("axisarrays/nameddims.jl")

  @require DimensionalData="0703355e-b756-11e9-17c0-8b28908087d0" include("axisarrays/dimensionaldata.jl")

  @require AxisArrays="39de3d68-74b9-583c-8d2d-e117c070f3a9" include("axisarrays/axisarrays.jl")

  @require AxisIndices="f52c9ee2-1b1c-4fd8-8546-6350938c7f11" include("axisarrays/axisindices.jl")

  @require AxisKeys="94b1ba4f-4ee9-5380-92f1-94cde586c3c5" include("axisarrays/axiskeys.jl")

  @require ArchGDAL="c9ce4bd3-c3d5-55b8-8973-c0e20141b8c3" begin 
    include("axisarrays/archgdal.jl")
    include("datasets/archgdal.jl")
  end


  @require Zarr="0a941bbe-ad1d-11e8-39d9-ab76183a1d99" include("datasets/zarr.jl")

  @require NetCDF="30363a11-5582-574a-97bb-aa9a979735b9" include("datasets/netcdf.jl")

end
=#


end


export dimvals, dimname, dimnames, iscontdim, iscompressed,
getattributes, getdata, yaxconvert
export get_var_handle, get_varnames, get_var_dims, get_var_attrs,
create_empty, add_var, allow_parallel_write,
to_dataset, allow_missings
end # module
