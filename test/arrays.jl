using YAXArrayBase, DimensionalData, AxisArrays, AxisIndices, Test

struct M
end
Base.ndims(::M) = 2
YAXArrayBase.getdata(::M)  = reshape(1:12,3,4)
YAXArrayBase.dimname(::M,i) = i==1 ? :x : :y
YAXArrayBase.dimvals(::M,i) = i==1 ? (0.5:1.0:2.5) : (1.5:0.5:3.0)
YAXArrayBase.getattributes(::M) = Dict{String,Any}("a1"=>5, "a2"=>"att")

@testset "AxisIndices" begin
    using AxisIndices
    d = yaxconvert(AxisIndices.AxisArray,M())
    @test d isa AxisIndices.AxisArray
    @test getdata(d) == reshape(1:12,3,4)
    @test YAXArrayBase.dimnames(d) == (:Dim_1, :Dim_2)
    @test dimvals(d,1) == 0.5:1.0:2.5
    @test dimvals(d,2) == 1.5:0.5:3.0
end

@testset "AxisArrays" begin
    using AxisArrays: AxisArrays
    d = yaxconvert(AxisArrays.AxisArray,M())
    @test d isa AxisArrays.AxisArray
    @test getdata(d) == reshape(1:12,3,4)
    @test YAXArrayBase.dimnames(d) == (:x, :y)
    @test dimvals(d,1) == 0.5:1.0:2.5
    @test dimvals(d,2) == 1.5:0.5:3.0
end

@testset "DimensionalData" begin
    using DimensionalData
    d = yaxconvert(DimensionalArray,M())
    @test d isa DimensionalArray
    @test getdata(d) == reshape(1:12,3,4)
    @test YAXArrayBase.dimnames(d) == (:x, :y)
    @test dimvals(d,1) == 0.5:1.0:2.5
    @test dimvals(d,2) == 1.5:0.5:3.0
    @test getattributes(d) == Dict{String,Any}("a1"=>5, "a2"=>"att")
end

@testset "ArchGDAL" begin
p = download("https://download.osgeo.org/geotiff/samples/gdal_eg/cea.tif")
using ArchGDAL
AG=ArchGDAL
    r = AG.readraster(p)
@test YAXArrayBase.dimnames(r) == (:Y, :X, :Band)
@test YAXArrayBase.dimvals(r,1) == -28493.166784412522:60.02213698319374:2298.189487965865
@test YAXArrayBase.getattributes(r)["projection"] == "+proj=cea +lat_ts=33.75 +lon_0=-117.333333333333 +x_0=0 +y_0=0 +datum=NAD27 +units=m +no_defs"
b = AG.getband(r,1)
    @test YAXArrayBase.dimnames(b) == (:Y, :X)
@test YAXArrayBase.dimvals(b,1) == -28493.166784412522:60.02213698319374:2298.189487965865
@test YAXArrayBase.getattributes(b)["projection"] == "+proj=cea +lat_ts=33.75 +lon_0=-117.333333333333 +x_0=0 +y_0=0 +datum=NAD27 +units=m +no_defs"
end
