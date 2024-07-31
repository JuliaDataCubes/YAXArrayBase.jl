module ArchGDALExt
import ArchGDAL: RasterDataset, AbstractRasterBand,
  getgeotransform, width, height, getname, getcolorinterp,
  getband, nraster, getdataset
using ArchGDAL: ArchGDAL as AG
  import YAXArrayBase: dimname, dimnames, dimvals, iscontdim, getattributes, getdata, yaxcreate

#include("archgdaldataset.jl")

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
function getattributes(a::RasterDataset)
    globatts = Dict{String,Any}(
        "projection_PROJ4"=>AG.toPROJ4(AG.newspatialref(AG.getproj(a))),
        "projection_WKT"=>AG.toWKT(AG.newspatialref(AG.getproj(a))),
    )
    bands = (getbandattributes(AG.getband(a, i)) for i in 1:size(a, 3))
    allbands = mergewith(bands...) do a1,a2
        isequal(a1,a2) ? a1 : missing
    end
    merge(globatts, allbands)
end


function dimname(::AbstractRasterBand, i)
    if i == 1
        return :Y
    elseif i == 2
        return :X
    else
        error("RasterDataset only has 3 dimensions")
    end
end
function dimvals(b::AbstractRasterBand, i)
    geo = getgeotransform(getdataset(b))
    if i == 1
        range(geo[1],length=width(b), step=geo[2])
    elseif i == 2
        range(geo[4],length=height(b), step=geo[6])
    else
        error("RasterDataset only has 3 dimensions")
    end
end
iscontdim(a::AbstractRasterBand, i) = true
function getattributes(a::AbstractRasterBand)
  atts = getattributes(AG.RasterDataset(AG.getdataset(a)))
  bandatts = getbandattributes(a)
  merge(atts, bandatts)
end

function insertattifnot!(attrs, val, name, condition)
    if !condition(val)
        attrs[name] = val
    end
end
function getbandattributes(a::AbstractRasterBand)
  atts = Dict{String,Any}()
  catdict = Dict((i-1)=>v for (i,v) in enumerate(AG.getcategorynames(a)))
  insertattifnot!(atts, AG.getnodatavalue(a), "missing_value", isnothing)
  insertattifnot!(atts, catdict, "labels", isempty)
  insertattifnot!(atts, AG.getunittype(a), "units", isempty)
  insertattifnot!(atts, AG.getoffset(a), "add_offset", iszero)
  insertattifnot!(atts, AG.getscale(a), "scale_factor", x->isequal(x, one(x)))
  atts
end
end