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

function DiskArrays.readblock!(b::GDALBand, aout::Matrix, r::AbstractUnitRange...)
        AG.read(b.filename) do ds
            AG.getband(ds, b.band) do bh
                DiskArrays.readblock!(bh, aout, r...) # ? what to do if size(aout) < r ranges ?, i.e. chunk reads! is a DiskArrays issue!
        end
    end
 end

function DiskArrays.readblock!(b::GDALBand, aout::Matrix, r::Tuple{AbstractUnitRange, AbstractUnitRange})
    DiskArrays.readblock!(b, aout, r...)
end

function DiskArrays.writeblock!(b::GDALBand, ain, r::AbstractUnitRange...)
    AG.read(b.filename, flags=AG.OF_UPDATE) do ds
        AG.getband(ds, b.band) do bh
            DiskArrays.writeblock!(bh, ain, r...)
        end
    end
end
function DiskArrays.readblock!(b::GDALBand, aout, r::AbstractUnitRange...)
    aout2 = similar(aout)
    DiskArrays.readblock!(b, aout2, r)
    aout .= aout2
end

struct GDALDataset
    filename::String
    bandsize::Tuple{Int,Int}
    projection::Union{String, AG.AbstractSpatialRef}
    trans::Vector{Float64}
    bands::OrderedDict{String}
end

function GDALDataset(filename; mode="r")
    AG.read(filename) do r
        nb = AG.nraster(r)
        allbands = map(1:nb) do iband
            b = AG.getband(r, iband)
            gb = GDALBand(b, filename, iband)
            name = AG.GDAL.gdalgetdescription(b.ptr)
            if isempty(name)
                name = AG.getname(AG.getcolorinterp(b))
            end
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
function YAB.get_var_handle(ds::GDALDataset, name; persist=true)
    if name == "X"
        range(ds.trans[1], length = ds.bandsize[1], step = ds.trans[2])
    elseif name == "Y"
        range(ds.trans[4], length = ds.bandsize[2], step = ds.trans[6])
    else
        ds.bands[name]
    end
end


YAB.get_varnames(ds::GDALDataset) = collect(keys(ds.bands))

function YAB.get_var_dims(ds::GDALDataset, d) 
    if d === "X"
        return ("X",)
    elseif d==="Y"
        return ("Y",)
    else
        return ("X", "Y")
    end
end

YAB.get_global_attrs(ds::GDALDataset) = Dict("projection"=>ds.projection)

function YAB.get_var_attrs(ds::GDALDataset, name)
    if name in ("Y", "X")
        Dict{String,Any}()
    else
        merge(ds.bands[name].attrs, YAB.get_global_attrs(ds))
    end
end

const colornames = AG.getname.(AG.GDALColorInterp.(0:16))

islat(s) = startswith(uppercase(s), "LAT")
islon(s) = startswith(uppercase(s), "LON")
isx(s) = uppercase(s) == "X"
isy(s) = uppercase(s) == "Y"

function totransform(x, y)
    xstep = diff(x)
    ystep = diff(y)
    if !all(isapprox(first(xstep)), xstep) || !all(isapprox(first(ystep)), ystep)
        throw(ArgumentError("Grid must have regular spacing"))
    end
    Float64[first(x), first(xstep), 0.0, first(y), 0.0, first(ystep)]
end
totransform(x::AbstractRange, y::AbstractRange) =
    Float64[first(x), step(x), 0.0, first(y), 0.0, step(y)]

getproj(userproj::String, attrs) = AG.importPROJ4(userproj)
getproj(userproj::AG.AbstractSpatialRef, attrs) = userproj

function getproj(::Nothing, attrs)
    if haskey(attrs, "projection")
        return AG.importWKT(attrs["projection"])
    elseif haskey(attrs, "projection_PROJ4")
        return AG.importPROJ4(attrs["projection_PROJ4"])
    elseif haskey(attrs, "projection_WKT")
        return AG.importWKT(attrs["projection_WKT"])
    else
        error("Could not determine output projection from attributes, please specify userproj")
    end
end

function YAB.create_dataset(
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
    # ? flip dimnames and dimvals, this needs a more generic solution!
    dimnames = reverse(dimnames)
    dimvals = reverse(dimvals)

    @assert length(dimnames) == 2
    merged_varattrs = merge(varattrs...)

    proj, trans = if islon(dimnames[1]) && islat(dimnames[2])
        #Lets set the crs to EPSG:4326
        proj = AG.importEPSG(4326)
        trans = totransform(dimvals[1], dimvals[2])
        proj, trans
    elseif isx(dimnames[1]) && isy(dimnames[2])
        # Try to find out crs
        all_attrs = merge(gatts, merged_varattrs)
        proj = getproj(userproj, all_attrs)
        trans = totransform(dimvals[1], dimvals[2])
        proj, trans
    else
        error("Did not find x, y or lon, lat dimensions in dataset")
    end
    cs = first(varchunks)
    @assert all(isequal(varchunks[1]), varchunks)

    # driver = AG.getdriver(AG.extensiondriver(outpath)) # ? it looks like this driver (for .tif) is not working

    if !endswith(lowercase(outpath), ".tif") && !endswith(lowercase(outpath), ".tiff")
        outpath = outpath * ".tif"
    end
    # Use this:
    driver = AG.getdriver("GTiff")

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
        options = [
            "BLOCKXSIZE=$(cs[1])",
            "BLOCKYSIZE=$(cs[2])",
            "TILED=YES",
            "COMPRESS=LZW"
            ]
    ) do ds
        AG.setgeotransform!(ds, trans)
        bands = map(1:length(varnames)) do i
            b = AG.getband(ds, i)
            icol = findfirst(isequal(varnames[i]), colornames)
            if isnothing(icol)
                AG.setcolorinterp!(b, AG.GDALColorInterp(0))
            else
                AG.setcolorinterp!(b, AG.GDALColorInterp(icol - 1))
            end
            AG.GDAL.gdalsetdescription(b.ptr, varnames[i])
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

function __init__()
    @info "new driver key :gdal, updating backendlist."
    YAB.backendlist[:gdal] = GDALDataset
    push!(YAB.backendregex,r".tif$"=>GDALDataset)
    push!(YAB.backendregex,r".gtif$"=>GDALDataset)
    push!(YAB.backendregex,r".tiff$"=>GDALDataset)
    push!(YAB.backendregex,r".gtiff$"=>GDALDataset)
end