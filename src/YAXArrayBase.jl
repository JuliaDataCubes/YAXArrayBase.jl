module YAXArrayBase
using Requires: @require
using DataStructures: OrderedDict

include("datasets/datasetinterface.jl")
include("axisarrays/axisinterface.jl")

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

  @require DimensionalData="0703355e-b756-11e9-17c0-8b28908087d0" begin
  using .DimensionalData: DimensionalArray, DimensionalData, data, Dim, metadata

  _dname(::DimensionalData.Dim{N}) where N = N
  dimname(x::DimensionalArray, i) = _dname(DimensionalData.dims(x)[i])


  dimvals(x::DimensionalArray,i) = DimensionalData.dims(x)[i].val

  getdata(x::DimensionalArray) = data(x)

  getattributes(x::DimensionalArray) = metadata(x)

  function yaxcreate(::Type{<:DimensionalArray},data,dnames,dvals,atts)
    d = ntuple(ndims(data)) do i
      Dim{Symbol(dnames[i])}(dvals[i])
    end
    DimensionalArray(data,d,metadata = atts)
  end
  end

  @require AxisArrays="39de3d68-74b9-583c-8d2d-e117c070f3a9" begin
  using .AxisArrays: AxisArrays, AxisArray

  dimname(a::AxisArray, i) = AxisArrays.axisnames(a)[i]
  dimnames(a::AxisArray) = AxisArrays.axisnames(a)
  dimvals(a::AxisArray, i) = AxisArrays.axisvalues(a)[i]
  iscontdim(a::AxisArray, i) = AxisArrays.axistrait(AxisArrays.axes(a,i)) <: AxisArrays.Dimensional
  getdata(a::AxisArray) = parent(a)
  function yaxcreate(::Type{<:AxisArray}, data, dnames, dvals, atts)
    d = ntuple(ndims(data)) do i
      dnames[i] => dvals[i]
    end
    AxisArray(data; d...)
  end
  end

  # @require AxisIndices="f52c9ee2-1b1c-4fd8-8546-6350938c7f11" begin
  # using .AxisIndices: AbstractAxis, AxisIndicesArray
  #
  # valfromaxis(ax::AbstractAxis) = keys(ax)
  #
  # getdata(a::AxisIndicesArray) = parent(a)
  #
  # yaxcreate(::Type{<:AxisIndicesArray}, data, dnames, dvals, atts) =
  #   AxisIndicesArray(data, map(i->dvals[i], 1:ndims(data))...)
  # end

  @require ArchGDAL="c9ce4bd3-c3d5-55b8-8973-c0e20141b8c3" begin
  import .ArchGDAL: RasterDataset, AbstractRasterBand,
    getgeotransform, width, height, getname, getcolorinterp,
    getband, nraster, getdataset
  function dimname(a::RasterDataset, i)
      if i == 1
          return :Y
      elseif i == 2
          return :X
      elseif i == 3
          return :Band
      else
          error("RasterDataset only has 3 dimensions")
      end
  end
  function dimvals(a::RasterDataset, i)
      if i == 1
          geo=getgeotransform(a)
          latr = range(geo[1],length=width(a), step=geo[2])
      elseif i == 2
          geo=getgeotransform(a)
          range(geo[4],length=height(a), step=geo[6])
      elseif i == 3
          colnames = map(ib -> getname(getcolorinterp(getband(a,ib))),1:nraster(a))
          if !allunique(colnames)
              colnames = string.("Band_",1:nraster(a))
          end
          colnames
      else
          error("RasterDataset only has 3 dimensions")
      end
  end
  iscontdim(a::RasterDataset, i) = i < 3 ? true : nraster(a)<8
  getattributes(a::RasterDataset) =
    Dict{String,Any}("projection"=>ArchGDAL.toPROJ4(ArchGDAL.newspatialref(ArchGDAL.getproj(a))))


  function dimname(::AbstractRasterBand, i)
      if i == 1
          return :Y
      elseif i == 2
          return :X
      else
          error("RasterDataset only has 3 dimiensions")
      end
  end
  function dimvals(b::AbstractRasterBand, i)
      geo = getgeotransform(getdataset(b))
      if i == 1
          range(geo[1],length=width(b), step=geo[2])
      elseif i == 2
          range(geo[4],length=height(b), step=geo[6])
      else
          error("RasterDataset only has 3 dimiensions")
      end
  end
  iscontdim(a::AbstractRasterBand, i) = true
  getattributes(a::AbstractRasterBand) =
    getattributes(ArchGDAL.RasterDataset(ArchGDAL.getdataset(a)))

  end

  @require Zarr="0a941bbe-ad1d-11e8-39d9-ab76183a1d99" include("datasets/zarr.jl")

  @require NetCDF="30363a11-5582-574a-97bb-aa9a979735b9" include("datasets/netcdf.jl")




end


export dimvals, dimname, dimnames, iscontdim, iscompressed,
getattributes, getdata, yaxconvert
export get_var_handle, get_varnames, get_var_dims, get_var_attrs,
create_empty, add_var, allow_parallel_write,
to_dataset, allow_missings
end # module
