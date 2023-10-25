module ArchGDALExt

using YAXArrayBase, ArchGDAL

include("ArchGDALArrays.jl")
include("ArchGDALDatasets.jl")

function __init__()
    YAXArrayBase.backendlist[:gdal] = GDALDataset
    push!(YAXArrayBase.backendregex,r".tif$"=>GDALDataset)
    push!(YAXArrayBase.backendregex,r".gtif$"=>GDALDataset)
    push!(YAXArrayBase.backendregex,r".tiff$"=>GDALDataset)
    push!(YAXArrayBase.backendregex,r".gtiff$"=>GDALDataset)
end

end
