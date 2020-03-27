var documenterSearchIndex = {"docs":
[{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"EditURL = \"https://github.com/JuliaPlots/AlgebraOfGraphics.jl/blob/master/docs/src/generated/tutorial.jl\"","category":"page"},{"location":"generated/tutorial/#Tutorial-1","page":"Tutorial","title":"Tutorial","text":"","category":"section"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"Define a \"plotting package agnostic\" algebra of graphics based on a few simple building blocks that can be combined using + and *. Highly experimental proof of concept, which may break often. The functions primary, data, and spec generate AbstractEdge objects. These AbstractEdges can be combined into trees with * (vertical composition), or + (horizontal composition). The resulting Tree can then be plotted with a package that supports it.","category":"page"},{"location":"generated/tutorial/#Working-with-tables-1","page":"Tutorial","title":"Working with tables","text":"","category":"section"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"using RDatasets: dataset\nusing AlgebraOfGraphics: table, data, primary, spec\nusing AbstractPlotting, CairoMakie\nmpg = dataset(\"ggplot2\", \"mpg\");\ncols = data(:Displ, :Hwy);\ngrp = primary(color = :Cyl);\nscat = spec(Scatter, markersize = 2)\npipeline = cols * scat\ntable(mpg) * pipeline |> plot\nAbstractPlotting.save(\"scatter.svg\", AbstractPlotting.current_scene()); nothing #hide","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"(Image: )","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"Now let's simply add grp to the pipeline to do the grouping.","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"table(mpg) * grp * pipeline |> plot\nAbstractPlotting.save(\"grouped_scatter.svg\", AbstractPlotting.current_scene()); nothing #hide","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"(Image: ) Traces can be added together with +.","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"using StatsMakie: linear\nlin = spec(linear, linewidth = 5)\npipenew = cols * (scat + lin)\ntable(mpg) * pipenew |> plot\nAbstractPlotting.save(\"linear.svg\", AbstractPlotting.current_scene()); nothing #hide","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"(Image: ) We can put grouping in the pipeline (we filter to avoid a degenerate group).","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"table(filter(row -> row.Cyl != 5, mpg)) * grp * pipenew |> plot\nAbstractPlotting.save(\"grouped_linear.svg\", AbstractPlotting.current_scene()); nothing #hide","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"(Image: ) This is a more complex example, where we split the scatter plot, but do the linear regression with all the data.","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"different_grouping = grp * scat + lin\ntable(mpg) * cols * different_grouping |> plot\nAbstractPlotting.save(\"semi_grouped.svg\", AbstractPlotting.current_scene()); nothing #hide","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"(Image: )","category":"page"},{"location":"generated/tutorial/#Non-tabular-data-1","page":"Tutorial","title":"Non tabular data","text":"","category":"section"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"The framework is not specific to tables, but can be used with anything that the plotting package supports.","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"using AlgebraOfGraphics: dims\nx = [-pi..0, 0..pi]\ny = [sin cos] # We use broadcasting semantics on `tuple.(x, y)`.\ndata(x, y) * primary(color = dims(1), linestyle = dims(2)) * spec(linewidth = 10) |> plot\nAbstractPlotting.save(\"functions.svg\", AbstractPlotting.current_scene()); nothing #hide","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"(Image: )","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"using Distributions\nmus = 1:4\nshapes = [6, 10]\ngs = InverseGaussian.(mus, shapes')\ngeom = spec(linewidth = 5)\ngrp = primary(color = dims(1), linestyle = dims(2))\ndata(fill(0..5), gs) * grp * geom |> plot\nAbstractPlotting.save(\"distributions.svg\", AbstractPlotting.current_scene()); nothing #hide","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"(Image: )","category":"page"},{"location":"generated/tutorial/#Layout-1","page":"Tutorial","title":"Layout","text":"","category":"section"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"Using the MakieLayout package it is possible to create plots where categorical variables inform the layout.","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"using MakieLayout\nusing AlgebraOfGraphics: layoutplot\niris = dataset(\"datasets\", \"iris\")\ncols = data([:SepalLength, :SepalWidth], [:PetalLength :PetalWidth])\ngrp = primary(layout_x = dims(1), layout_y = dims(2), color = :Species)\ngeom = spec(Scatter, markersize = 0.1) + spec(linear, linewidth = 3)\ntable(iris) * cols * grp * geom |> layoutplot\nAbstractPlotting.save(\"layout.svg\", AbstractPlotting.current_scene()); nothing #hide","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"(Image: )","category":"page"},{"location":"generated/tutorial/#Slicing-context-1","page":"Tutorial","title":"Slicing context","text":"","category":"section"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"The algebra of graphics logic can be easily extended to novel context. For example, slice implements the \"slices are series\" approach of Plots.","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"using AlgebraOfGraphics: slice\ns = slice(1) * data(rand(5, 3), rand(5, 3, 2))\ngrp = primary(color = dims(2), layout_x = dims(3))\ns * grp * spec(Scatter, markersize = 0.1) |> layoutplot\nAbstractPlotting.save(\"arrays.svg\", AbstractPlotting.current_scene()); nothing #hide","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"(Image: )","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"","category":"page"},{"location":"generated/tutorial/#","page":"Tutorial","title":"Tutorial","text":"This page was generated using Literate.jl.","category":"page"},{"location":"#Introduction-1","page":"Introduction","title":"Introduction","text":"","category":"section"}]
}
