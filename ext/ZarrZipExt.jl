module ZarrZipExt
using ZarrZip: ZipStore
import DiskArrays: AbstractDiskArray, DiskArrays, Unchunked, Chunked, GridChunks
import YAXArrayBase: YAXArrayBase as YAB

#Add ability to read zipped zarrs
YAB.zarr_zipstore(path::AbstractString) = ZipStore(SimpleFileDiskArray(path))

struct SimpleFileDiskArray{C<:Union{Int,Nothing}} <: AbstractDiskArray{UInt8,1}
  file::String
  s::Int
  chunksize::C
end
Base.size(s::SimpleFileDiskArray) = (s.s,)
function SimpleFileDiskArray(filename; chunksize=nothing)
  isfile(filename) || throw(ArgumentError("File $filename does not exist"))
  s = filesize(filename)
  SimpleFileDiskArray(filename, s, chunksize)
end
function DiskArrays.readblock!(a::SimpleFileDiskArray, aout, i::AbstractUnitRange)
  open(a.file) do f
    seek(f, first(i) - 1)
    read!(f, aout)
  end
end
DiskArrays.haschunks(a::SimpleFileDiskArray) = a.chunksize === nothing ? Unchunked() : Chunked()
function DiskArrays.eachchunk(a::SimpleFileDiskArray)
  if a.chunksize === nothing
    DiskArrays.estimate_chunksize(a)
  else
    GridChunks((a.s,), (a.chunksize,))
  end
end

end
