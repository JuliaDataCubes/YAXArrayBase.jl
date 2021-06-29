import .ArchGDAL: RasterDataset, AbstractRasterBand,
  getgeotransform, width, height, getname, getcolorinterp,
  getband, nraster, getdataset, ArchGDAL
using .ArchGDAL.DiskArrays: GridChunks, DiskArrays, eachchunk
const AG = ArchGDAL

struct GDALBand{T} <: AG.DiskArrays.AbstractDiskArray{T,2}
    filename::String
    band::Int
    size::Tuple{Int,Int}
    attrs::Dict{String,Any}
    cs::GridChunks{2}
end
function GDALBand(b, filename, i)
    s = size(b)
    atts = getbandattributes(b)
    GDALBand{AG.pixeltype(b)}(filename, i, s, atts, eachchunk(b))
end
Base.size(b::GDALBand) = b.size
DiskArrays.eachchunk(b::GDALBand) = b.cs
DiskArrays.haschunks(::GDALBand) = DiskArrays.Chunked()
function DiskArrays.readblock!(b::GDALBand, aout, r::AbstractUnitRange...)
    AG.read(b.filename) do ds
        AG.getband(ds, b.band) do bh
            DiskArrays.readblock!(bh, aout, r...)
        end
    end
end
function DiskArrays.writeblock!(b::GDALBand, ain, r::AbstractUnitRange...)
    AG.read(b.filename, flags=AG.OF_Update) do ds
        AG.getband(ds, b.band) do bh
            DiskArrays.writeblock!(bh, ain, r...)
        end
    end
end

struct GDALDataset
    filename::String
    bandsize::Tuple{Int,Int}
    projection::String
    trans::Vector{Float64}
    bands::OrderedDict{String}
end

function GDALDataset(filename)
    AG.read(filename) do r
        nb = AG.nraster(r)
        allbands = map(1:nb) do iband
            b = AG.getband(r, iband)
            gb = GDALBand(b, filename, iband)
            name = AG.getname(AG.getcolorinterp(b))
            name => gb
        end
        proj = AG.getproj(r)
        trans = AG.getgeotransform(r)
        s = AG._common_size(r)
        allnames = first.(allbands)
        if !allunique(allnames)
            allbands = ["Band$i"=>last(v) for (i,v) in enumerate(allbands)]
        end
        GDALDataset(filename, s[1:end-1], proj, trans, OrderedDict(allbands))
    end
end
Base.haskey(ds::GDALDataset, k) = in(k, ("X", "Y")) || haskey(ds.bands, k)
#Implement Dataset interface
function get_var_handle(ds::GDALDataset, name)
    if name == "X"
        range(ds.trans[1], length = ds.bandsize[1], step = ds.trans[2])
    elseif name == "Y"
        range(ds.trans[4], length = ds.bandsize[2], step = ds.trans[6])
    else
        ds.bands[name]
    end
end


get_varnames(ds::GDALDataset) = collect(keys(ds.bands))

get_var_dims(ds::GDALDataset, _) = ("X", "Y")

function get_var_attrs(ds::GDALDataset, name)
    if name in ("Y", "X")
        Dict{String,Any}()
    else
        ds.bands[name].attrs
    end
end

const colornames = AG.getname.(AG.GDAL.GDALColorInterp.(0:16))

islat(s) = startswith(uppercase(s), "LAT")
islon(s) = startswith(uppercase(s), "LON")
isx(s) = uppercase(s) == "X"
isy(s) = uppercase(s) == "Y"

function totransform(x, y)
    xstep = diff(x)
    ystep = diff(y)
    if !all(isapprox(first(xstep)), xstep) && !all(isapprox(first(ystep)), ystep)
        throw(ArgumentError("Grid must have regular spacing"))
    end
    Float64[first(x), first(xstep), 0.0, first(y), 0.0, first(ystep)]
end
totransform(x::AbstractRange, y::AbstractRange) =
    Float64[first(x), step(x), 0.0, first(y), 0.0, step(y)]
getproj(userproj::String, attrs) = AG.importPROJ4(userproj)
getproj(userproj::AG.AbstractSpatialRef, attrs) = userproj
function getproj(userproj::Nothing, attrs)
    if haskey(attr, "projection_PROJ4")
        return AG.importPROJ4(attr["projection_PROJ4"])
    elseif haskey(attr, "projection_WKT")
        return AG.importWKT(attr["projection_WKT"])
    else
        error(
            "Could not determine output projection from attributes, please specify userproj",
        )
    end
end


function create_dataset(
    ::Type{<:GDALDataset},
    outpath,
    gatts,
    dimnames,
    dimvals,
    dimattrs,
    vartypes,
    varnames,
    vardims,
    varattrs,
    varchunks;
    userproj = nothing,
    kwargs...,
)
    @assert length(dimnames) == 2
    proj, trans = if islon(dimnames[1]) && islat(dimnames[2])
        #Lets set srs to EPSG:4326
        proj = AG.importEPSG(4326)
        trans = totransform(dimvals[1], dimvals[2])
        proj, trans
    elseif isx(dimnames[1]) && isy(dimnames[2])
        #Try to find out srs
        proj = getproj(userproj, gatts)
        trans = totransform(dimvals[1], dimvals[2])
        proj, trans
    else
        error("Did not find x, y or lon, lat dimensions in dataset")
    end
    cs = first(varchunks)
    @assert all(isequal(varchunks[1]), varchunks)

    driver = AG.getdriver(AG.extensiondriver(outpath))

    nbands = length(varnames)
    dtype = promote_type(vartypes...)
    s = (length.(dimvals)...,)
    bands = AG.create(
        outpath;
        driver = driver,
        width = length(dimvals[1]),
        height = length(dimvals[2]),
        nbands = nbands,
        dtype = dtype,
        options = ["BLOCKXSIZE=$(cs[1])", "BLOCKYSIZE=$(cs[2])"]
    ) do ds
        AG.setgeotransform!(ds, trans)
        bands = map(1:length(varnames)) do i
            b = AG.getband(ds, i)
            icol = findfirst(isequal(varnames[i]), colornames)
            if isnothing(icol)
                AG.setcolorinterp!(b, AG.GDAL.GDALColorInterp(0))
            else
                AG.setcolorinterp!(b, AG.GDAL.GDALColorInterp(icol - 1))
            end
            atts = varattrs[i]
            haskey(atts, "missing_value") && AG.setnodatavalue!(b, atts["missing_value"])
            if haskey(atts, "labels")
                labeldict = atts[labels]
                maxlabel = maximum(keys(labeldict))
                kt = keytype(labeldict)
                labelvec = [haskey(labeldict, et(i)) ? labeldict[et(i)] : "" for i = 0:maxlabel]
                AG.setcategorynames!(b, labelvec)
            end
            haskey(atts, "units") && AG.setunittype!(b, atts["units"])
            haskey(atts, "scale_factor") && AG.setscale!(b, atts["scale_factor"])
            haskey(atts, "add_offset") && AG.setoffset!(b, atts["add_offset"])
            GDALBand{dtype}(outpath, i, s, atts, AG.DiskArrays.GridChunks(s,cs))
        end
    end
    return GDALDataset(outpath, s, AG.toPROJ4(proj), trans, OrderedDict(vn=>b for (vn,b) in zip(varnames, bands)))
end

allow_parallel_write(::Type{<:GDALDataset}) = false
allow_parallel_write(::GDALDataset) = false

allow_missings(::Type{<:GDALDataset}) = false
allow_missings(::GDALDataset) = false

backendlist[:gdal] = GDALDataset
push!(backendregex,r".tif$"=>GDALDataset)
push!(backendregex,r".gtif$"=>GDALDataset)
push!(backendregex,r".tiff$"=>GDALDataset)
push!(backendregex,r".gtiff$"=>GDALDataset)