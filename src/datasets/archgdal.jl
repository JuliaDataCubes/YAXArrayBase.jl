const AG = ArchGDAL

struct GDALBand{T} <: AbstractDiskArray{T,2}
    filename::String
    band::Int
    size::Tuple{Int,Int}
    attrs::Dict{String,Any}
    cs::GridChunks{2}
end
function GDALBand(b,filename,i)
    s = size(b)
    atts = getbandattributes(b)
    GDALBand{AG.pixeltype(b)}(filename, i, s, atts, eachchunk(b))
end
Base.size(b::GDALBand) = b.size
DiskArrays.eachchunk(b::GDALBand) = b.cs
DiskArrays.haschunks(::GDALBand) = DiskArrays.Chunked()
function DiskArrays.readblock!(b::GDALBand,aout,r::AbstractUnitRange...)
    AG.read(b.filename) do ds
        AG.getband(ds,b.band) do bh
            DiskArrays.readblock!(bh,aout,r...)
        end
    end
end

struct GDALDataset
    filename::String
    bandsize::Tuple{Int,Int}
    projection::String
    trans::NTuple{6,Float64}
    bands::OrderedDict{String}
end

function GDALDataset(filename)
    AG.read(filename) do r
        nb = AG.nraster(r)
        allbands = map(1:nb) do iband
            b = AG.getband(r,iband)
            gb = GDALBand(b, filename,iband)
            name = AG.getname(AG.getcolorinterp(b))
            isempty(name) && (name = string("Band",iband))
            name => gb
        end
        proj = AG.getproj(r)
        trans = (AG.getgeotransform(r)...,)
        s = AG._common_size(r)
        GDALDataset(filename, s[1:end-1], proj, trans, OrderedDict(allbands))
    end
end
Base.haskey(ds::GDALDataset, k) = in(k,("X","Y")) || haskey(ds.bands,k)
#Implement Dataset interface
function get_var_handle(ds::GDALDataset, name) 
    if name == "X"
        range(ds.trans[1],length=ds.bandsize[1], step=ds.trans[2])
    elseif name == "Y"
        range(ds.trans[4],length=ds.bandsize[2], step=ds.trans[6])
    else
        ds.bands[name]
    end
end
    

get_varnames(ds::GDALDataset) = collect(keys(ds.bands))

get_var_dims(ds::GDALDataset, _) = ("X", "Y")

function get_var_attrs(ds::GDALDataset,name) 
    if name in ("Y","X")
        Dict{String,Any}()
    else
        ds.bands[name].attrs
    end
end