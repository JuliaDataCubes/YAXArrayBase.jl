module ArchGDALExt

using ArchGDAL: RasterDataset, AbstractRasterBand,
  getgeotransform, width, height, getname, getcolorinterp,
  getband, nraster, getdataset, ArchGDAL
using ArchGDAL.DiskArrays: GridChunks, DiskArrays, eachchunk

const AG = ArchGDAL

using DataStructures: OrderedDict
import YAXArrayBase: create_dataset, get_var_handle, get_varnames, get_var_attrs,
  get_var_dims, get_global_attrs, create_dataset, add_var, create_empty, backendlist,
  backendregex, dimname, dimvals, iscontdim, getattributes, GDALDataset
using YAXArrayBase: backendlist, backendregex

include("ArchGDALArrays.jl")
include("ArchGDALDatasets.jl")

function __init__()
    backendlist[:gdal] = GDALDataset
    push!(backendregex,r".tif$"=>GDALDataset)
    push!(backendregex,r".gtif$"=>GDALDataset)
    push!(backendregex,r".tiff$"=>GDALDataset)
    push!(backendregex,r".gtiff$"=>GDALDataset)
end

end
