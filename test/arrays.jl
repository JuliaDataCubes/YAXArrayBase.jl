using TestItems


@testitem "AxisKeys" begin
    using AxisKeys: KeyedArray
    include("mock.jl")
    d = yaxconvert(KeyedArray,M())
    @test d isa KeyedArray
    @test getdata(d) == reshape(1:12,3,4)
    @test YAXArrayBase.dimnames(d) == (:x, :y)
    @test dimvals(d,1) == 0.5:1.0:2.5
    @test dimvals(d,2) == 1.5:0.5:3.0
end


@testitem "AxisArrays" begin
    using AxisArrays: AxisArrays
    include("mock.jl")
    d = yaxconvert(AxisArrays.AxisArray,M())
    @test d isa AxisArrays.AxisArray
    @test getdata(d) == reshape(1:12,3,4)
    @test YAXArrayBase.dimnames(d) == (:x, :y)
    @test dimvals(d,1) == 0.5:1.0:2.5
    @test dimvals(d,2) == 1.5:0.5:3.0
end

@testitem "NamedTuples" begin
    include("mock.jl")
    d = yaxconvert(NamedTuple,M())
    @test d isa NamedTuple
    @test getdata(d) == reshape(1:12,3,4)
    @test YAXArrayBase.dimnames(d) == (:x, :y)
    @test dimvals(d,1) == 0.5:1.0:2.5
    @test dimvals(d,2) == 1.5:0.5:3.0
end

@testitem "NamedDims" begin
    using NamedDims: NamedDimsArray
    include("mock.jl")
    d = yaxconvert(NamedDimsArray,M())
    @test d isa NamedDimsArray
    @test getdata(d) == reshape(1:12,3,4)
    @test YAXArrayBase.dimnames(d) == (:x, :y)
end

@testitem "DimensionalData" begin
    using DimensionalData
    include("mock.jl")
    d = yaxconvert(DimArray,M())
    @test d isa DimArray
    @test getdata(d) == reshape(1:12,3,4)
    @test YAXArrayBase.dimnames(d) == (:x, :y)
    @test dimvals(d,1) == 0.5:1.0:2.5
    @test dimvals(d,2) == 1.5:0.5:3.0
    @test getattributes(d) == Dict{String,Any}("a1"=>5, "a2"=>"att")
end

@testitem "ArchGDAL" begin
  import Downloads
  include("mock.jl")
  p = Downloads.download("https://download.osgeo.org/geotiff/samples/gdal_eg/cea.tif")
  using ArchGDAL
  AG=ArchGDAL
  r = AG.readraster(p)
  @test YAXArrayBase.dimnames(r) == (:Y, :X, :Band)
  @test YAXArrayBase.dimname(r,1) == :Y
  @test YAXArrayBase.dimname(r,2) == :X
  @test YAXArrayBase.dimname(r,3) == :Band
  @test YAXArrayBase.dimvals(r,1) == -28493.166784412522:60.02213698319374:2298.189487965865
  @test YAXArrayBase.dimvals(r,2) == 4.2558845438021915e6:-60.02213698319374:4.22503316539283e6
  @test YAXArrayBase.dimvals(r,3) == ["Gray"]
  @test_throws Exception YAXArrayBase.dimname(r,4)
  @test_throws Exception YAXArrayBase.dimvals(r,4)
  @test YAXArrayBase.iscontdim(r,1) == true
  @test YAXArrayBase.iscontdim(r,2) == true
  @test YAXArrayBase.iscontdim(r,3) == true
  @test YAXArrayBase.getattributes(r)["projection_PROJ4"] == "+proj=cea +lat_ts=33.75 +lon_0=-117.333333333333 +x_0=0 +y_0=0 +datum=NAD27 +units=m +no_defs"
  b = AG.getband(r,1)
  @test YAXArrayBase.dimnames(b) == (:Y, :X)
  @test YAXArrayBase.dimname(b,1) == :Y
  @test YAXArrayBase.dimname(b,2) == :X
  @test YAXArrayBase.dimvals(b,1) == -28493.166784412522:60.02213698319374:2298.189487965865
  @test YAXArrayBase.dimvals(b,2) == 4.2558845438021915e6:-60.02213698319374:4.22503316539283e6
  @test_throws Exception YAXArrayBase.dimname(b,3)
  @test_throws Exception YAXArrayBase.dimvals(b,3)
  @test YAXArrayBase.iscontdim(b,1) == true
  @test YAXArrayBase.iscontdim(b,2) == true
  @test YAXArrayBase.getattributes(b)["projection_PROJ4"] == "+proj=cea +lat_ts=33.75 +lon_0=-117.333333333333 +x_0=0 +y_0=0 +datum=NAD27 +units=m +no_defs"
end
