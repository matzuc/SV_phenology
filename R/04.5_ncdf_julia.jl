# install netcdf for julia
using Pkg
Pkg.add("NetCDF")

using NetCDF

path_in = "D:\\Dropbox\\R_projects\\SV_phenology\\data\\daily_coarsened"

# I'm going to make an assumption on the variable name since it wasn't given in the Python code.
# Let's assume it's "data_var". Adjust as needed.
var_name = "CHL"

# Load all .nc files from the directory and subdirectories


function list_nc_files_recursive(path)
    all_files = String[]
    for dir in walkdir(path)
        dirname, dirs, files = dir
        for file in files
            if endswith(file, ".nc")
                push!(all_files, joinpath(dirname, file))
            end
        end
    end
    return all_files
end

files = list_nc_files_recursive(path_in)
datasets = [NetCDF.open(filename) for filename in files]

# Concatenate along the time dimension
# This assumes that all datasets have the same spatial dimensions and variables
#concatenated_data = vcat([ncread(ds, var_name) for ds in files]...; dims = 1)
concatenated_data = vcat([ncread(ds, var_name) for ds in files]...)

# Calculate smoothed data (I'm approximating the rolling mean here; consider implementing a more accurate version)
ds_smooth = (circshift(concatenated_data, 1, dims=1) .+ concatenated_data .+ circshift(concatenated_data, -1, dims=1)) ./ 3.0
ds_smooth = (circshift(ds_smooth, 1, dims=2) .+ ds_smooth .+ circshift(ds_smooth, -1, dims=2)) ./ 3.0

# Calculate 3-week rolling mean
ds_3w = [mean(ds_smooth[i:i+20, :, :], dims=1) for i in 1:size(ds_smooth, 1)-20]

# Attach day-of-year (DOY) and compute mean values for each DOY
doy = [Dates.dayofyear(Dates.unix2datetime(time_val)) for time_val in read(datasets[1], "time")]
ds_3w_doy = [Dates.dayofyear(Dates.unix2datetime(time_val)) for time_val in 1:size(ds_3w, 1)]
ds_mean = [mean(ds_3w[ds_3w_doy .== d, :, :], dims=1) for d in doy]

# Write the mean values to a NetCDF file
# Note: This is just a starting point and may need to be adjusted based on the exact format and attributes of your data.
ds_out = NetCDF.create("CHL_mean_smoothed_julia.nc")
NetCDF.defDim(ds_out, "time", length(doy))
NetCDF.defDim(ds_out, "latitude", size(ds_mean, 2))
NetCDF.defDim(ds_out, "longitude", size(ds_mean, 3))
NetCDF.defVar(ds_out, var_name, Float64, ("time", "latitude", "longitude"))
write(ds_out, var_name, ds_mean)
NetCDF.close(ds_out)
