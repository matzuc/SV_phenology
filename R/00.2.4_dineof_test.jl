using Pkg
#Pkg.add("NetCDF")
#Pkg.clone("https://github.com/jmbeckers/DINEOF/master")
Pkg.add("TSVD")
TSVD.jl


Pkg.add(PackageSpec(url="https://github.com/jmbeckers/DINEOF.jl.git"))
import Pkg; Pkg.precompile()
Pkg.instantiate()
Pkg.resolve()
using DINEOF
using NetCDF
using PyPlot