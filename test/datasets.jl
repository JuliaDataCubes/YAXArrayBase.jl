using YAXArrayBase, Test
@testset "Empty Backend" begin
  @test_throws "No backend found." YAXArrayBase.backendfrompath("test.zarr")
end

using NetCDF, Zarr

using Pkg.Artifacts
import Downloads
# This is the path to the Artifacts.toml we will manipulate
artifact_toml =  joinpath(@__DIR__,"Artifacts.toml")
ncar_hash = artifact_hash("ncar", artifact_toml)
if ncar_hash === nothing || !artifact_exists(ncar_hash)
  oldhash = ncar_hash
  ncar_hash = create_artifact() do artifact_dir     
    Downloads.download("https://www.unidata.ucar.edu/software/netcdf/examples/sresa1b_ncar_ccsm3-example.nc",joinpath(artifact_dir,"ncar.nc"))
  end
  if oldhash !== nothing
    unbind_artifact!(artifact_toml, "ncar")
  end
  bind_artifact!(artifact_toml, "ncar", ncar_hash)
end
p2 = joinpath(artifact_path(ncar_hash),"ncar.nc")

@testset "Reading NetCDF" begin

ds_nc = YAXArrayBase.to_dataset(p2)
vn = get_varnames(ds_nc)
@test sort(vn) == ["area", "lat", "lat_bnds", "lon", "lon_bnds", "msk_rgn",
 "plev", "pr", "tas", "time", "time_bnds", "ua"]
@test get_var_dims(ds_nc, "tas") == ["lon", "lat", "time"]
@test get_var_dims(ds_nc, "area") == ["lon", "lat"]
@test get_var_dims(ds_nc, "time") == ["time"]
@test get_var_dims(ds_nc, "time_bnds") == ["bnds", "time"]
@test get_var_attrs(ds_nc,"tas")["long_name"] == "air_temperature"
h = get_var_handle(ds_nc, "tas")
@test !YAXArrayBase.iscompressed(h)
@test all(isapprox.(h[1:2,1:2], [215.893 217.168; 215.805 217.03]))
@test allow_parallel_write(ds_nc) == false
@test allow_missings(ds_nc) == false
#Repeat the same test with an open get_var_handle
ds_nc2 = YAXArrayBase.to_dataset(p2)
YAXArrayBase.open_dataset_handle(ds_nc2) do ds_nc
  @test ds_nc.handle[] !== nothing
  vn = get_varnames(ds_nc)
  @test sort(vn) == ["area", "lat", "lat_bnds", "lon", "lon_bnds", "msk_rgn",
 "plev", "pr", "tas", "time", "time_bnds", "ua"]
  @test get_var_dims(ds_nc, "tas") == ["lon", "lat", "time"]
  @test get_var_dims(ds_nc, "area") == ["lon", "lat"]
  @test get_var_dims(ds_nc, "time") == ["time"]
  @test get_var_dims(ds_nc, "time_bnds") == ["bnds", "time"]
  @test get_var_attrs(ds_nc,"tas")["long_name"] == "air_temperature"
  h1 = get_var_handle(ds_nc, "tas",persist=true)
  @test !(h1 isa NetCDF.NcVar)
  @test !YAXArrayBase.iscompressed(h1)
  @test all(isapprox.(h1[1:2,1:2], [215.893 217.168; 215.805 217.03]))
  h2 = get_var_handle(ds_nc, "tas",persist=false)
  @test h2 isa NetCDF.NcVar
  @test !YAXArrayBase.iscompressed(h2)
  @test all(isapprox.(h2[1:2,1:2], [215.893 217.168; 215.805 217.03]))
  @test allow_parallel_write(ds_nc) == false
  @test allow_missings(ds_nc) == false
end
end

@testset "Reading Zarr" begin
p = "gs://cmip6/CMIP6/HighResMIP/CMCC/CMCC-CM2-HR4/highresSST-present/r1i1p1f1/6hrPlev/psl/gn/v20170706/"
ds_zarr = to_dataset(p,driver=:zarr)
vn = get_varnames(ds_zarr)
@test sort(vn) == ["lat", "lat_bnds", "lon", "lon_bnds", "psl", "time", "time_bnds"]
@test get_var_dims(ds_zarr, "psl") == ["lon", "lat", "time"]
@test get_var_dims(ds_zarr, "time") == ["time"]
@test get_var_dims(ds_zarr, "time_bnds") == ["bnds", "time"]
@test get_var_attrs(ds_zarr,"psl")["long_name"] == "Sea Level Pressure"
h = get_var_handle(ds_zarr, "psl")
@test YAXArrayBase.iscompressed(h)
@test all(isapprox.(h[1:2,1:2,1], [99360.8  99334.9; 99360.8  99335.4]))
@test allow_parallel_write(ds_zarr) == true
@test allow_missings(ds_zarr) == false
end
@testset "Reading ArchGDAL" begin
  using ArchGDAL
  import Downloads
  p3 = Downloads.download("https://download.osgeo.org/geotiff/samples/gdal_eg/cea.tif")
  ds_tif = YAXArrayBase.to_dataset(p3, driver=:gdal)
  vn = get_varnames(ds_tif)
  @test sort(vn) == ["Gray"]
  @test get_var_dims(ds_tif, "Gray") == ("X", "Y")
  @test haskey(get_var_attrs(ds_tif, "Gray"), "projection")
  h = get_var_handle(ds_tif, "Gray")
  @test !YAXArrayBase.iscompressed(h)
  @test all(isapprox.(h[1:2,1:2], [0x00 0x00; 0x00 0x00]))
  @test allow_parallel_write(ds_tif) == false
  @test allow_missings(ds_tif) == true
end
function test_write(T)
  p = tempname()
  ds = create_empty(T, p)
  add_var(ds, 0.5:1:9.5, "lon", ("lon",), Dict("units"=>"degrees_east"))
  add_var(ds, 20:-1.0:1, "lat", ("lat",), Dict("units"=>"degrees_north"))
  v = add_var(ds, Float32, "tas", (10,20), ("lon", "lat"), Dict{String,Any}("units"=>"Celsius"))

  v[:,:] = collect(reshape(1:200, 10, 20))

  @test sort(get_varnames(ds)) == ["lat","lon","tas"]
  @test get_var_dims(ds, "tas") == ["lon", "lat"]
  @test get_var_dims(ds, "lon") == ["lon"]
  @test get_var_attrs(ds,"tas")["units"] == "Celsius"
  h = get_var_handle(ds, "lon")
  @test h[:] == 0.5:1:9.5
  v = get_var_handle(ds, "tas")
  @test v[1:2,1:2] == [1 11; 2 12]
end

@testset "Writing NetCDF" begin
  test_write(YAXArrayBase.backendlist[:netcdf])
end

@testset "Writing Zarr" begin
  test_write(YAXArrayBase.backendlist[:zarr])
end
