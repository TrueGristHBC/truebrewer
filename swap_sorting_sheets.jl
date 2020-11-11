using DelimitedFiles, CSV, DataFrames, Revise

include("swap_gen.jl")

# Email, Name, Username, Level
brewers = DataFrame(CSV.read("participants2020.csv"))

# Generate swap matrix
writedlm("swap2020.csv", Int64.(swap_matrix(sum(brewers["Level"] .== 24), sum(brewers["Level"] .== 12))), ',')

brewers2 = ["$i. $(brewers["Name"][i]) (@$(lowercase(brewers["Username"][i])))" for i in 1:size(brewers, 1)]

swapmatrix = readdlm("swap2020.csv", ',', Bool)

io = open("truebrewerdrops.html", "w");
write(io, "<html>\n")
write(io,
"""
<head>
<style>
div {
page-break-before: always;
font-family:"Comic Sans MS";
font-size:20px;
}
</style>
</head>
""")
for i in eachindex(brewers2)
  write(io, "<div>\n")
  write(io, "<h2><br>$(brewers2[i]) provides beer to:</h2>\n")
  for r in (brewers2[swapmatrix[i,:][:]])
    write(io, r*"<br>\n")
  end
  write(io, "</div>\n\n")
end
write(io, "</html>")
close(io)



io = open("truebrewergets.html", "w");
write(io, "<html>\n")
write(io,
"""
<head>
<style>
div {
page-break-before: always;
font-family:"Comic Sans MS";
font-size:20px;
}
</style>
</head>
""")
for i in eachindex(brewers2)
  write(io, "<div>\n")
  write(io, "<h2><br>$(brewers2[i]) receives beer from:</h2>\n")
  for r in (brewers2[swapmatrix[:,i][:]])
    write(io, r*"<br>\n")
  end
  write(io, "</div>\n\n")
end
write(io, "</html>")
close(io)


io = open("truebrewernames.html", "w");
write(io, "<html>\n")
write(io,
"""
<head>
<style>
div {
page-break-before: always;
font-family:"Comic Sans MS";
font-size:30px;
}
</style>
</head>
""")
for i in eachindex(brewers2)
  write(io, "<div>\n")
  write(io, "<center><h1><br>$(brewers2[i])</h1></center>\n")
  write(io, "</div>\n\n")
end
write(io, "</html>")
close(io)
