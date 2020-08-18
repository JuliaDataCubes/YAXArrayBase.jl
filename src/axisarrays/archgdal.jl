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
