function MakieLayout.Legend(fg::FigureGrid)
    colorbar = _Colorbar_(fg)
    legend = _Legend_(fg)
    if !isnothing(colorbar)
        Colorbar(fg.figure[:, end + 1]; colorbar...)
    end
    if !isnothing(legend)
        Legend(fg.figure[:, end + 1], legend...)
    end
end

function has_zcolor(entry::Entry)
    return entry.plottype <: Union{Heatmap, Contour, Contourf, Surface} &&
        !haskey(entry.primary, :color) &&
        !haskey(entry.named, :color) &&
        !haskey(entry.attributes, :color)
end

function getlabeledcolorrange(grid)
    zcolor = any(has_zcolor, entries(grid))
    key = zcolor ? 3 : :color
    continuous_color_entries = Iterators.filter(entries(grid)) do entry
        return get(entry, key, nothing) isa AbstractArray{<:Number}
    end
    colorrange = compute_extrema(continuous_color_entries, key)
    label = compute_label(continuous_color_entries, key)
    return isnothing(colorrange) ? nothing : (label, colorrange)
end

function _Colorbar_(fg::FigureGrid)
    grid = fg.grid
    labeledcolorrange = getlabeledcolorrange(grid)
    isnothing(labeledcolorrange) && return
    label, limits = labeledcolorrange
    colormap = current_default_theme().colormap[]
    for entry in entries(grid)
        colormap = to_value(get(entry.attributes, :colormap, colormap))
    end
    return (; label, limits, colormap)
end

"""
    plottypes_attributes(entries)

Return plottypes and relative attributes, as two vectors of the same length,
for the given `entries`.
"""
function plottypes_attributes(entries)
    plottypes = PlotFunc[]
    attributes = Vector{Symbol}[]
    for entry in entries
        # FIXME: this should probably use the rescaled values
        plottype = Makie.plottype(entry.plottype, entry.positional...)
        n = findfirst(==(plottype), plottypes)
        attrs = (keys(entry.primary)..., keys(entry.named)...)
        if isnothing(n)
            push!(plottypes, plottype)
            push!(attributes, collect(Symbol, attrs))
        else
            union!(attributes[n], attrs)
        end
    end
    return plottypes, attributes
end

hassymbolkey((k, v)::Pair) = k isa Symbol

function _Legend_(fg::FigureGrid)
    grid = fg.grid

    # assume all subplots have same scales, to be changed to support free scales
    scales = filter(hassymbolkey, first(grid).scales)

    # remove keywords that don't support legends
    for key in [:row, :col, :layout, :stack, :dodge, :group]
        pop!(scales, key, nothing)
    end
    # if no legend-worthy keyword remains return nothing
    isempty(scales) && return nothing

    titles = unique!(collect(String, (scale.label for scale in values(scales))))
    # empty strings create difficulties with the layout
    nonemptytitles = map(t -> isempty(t) ? " " : t, titles)

    plottypes, attributes = plottypes_attributes(entries(grid))

    labels = Vector{String}[]
    elements_list = Vector{Vector{LegendElement}}[]

    # search in attributes if a color is given for e.g. lines/scatter
    legend_colors = unique([entry.attributes[:color] for entry in entries(grid) if haskey(entry.attributes, :color)])
    # if a single agreeable color is found, use that for the Legend entries
    legend_color = length(legend_colors) == 1 ? first(legend_colors) : nothing

    for title in titles
        label_attrs = [key for (key, val) in scales if val.label == title]
        uniquevalues = mapreduce(k -> datavalues(scales[k]), assert_equal, label_attrs)
        elements = map(eachindex(uniquevalues)) do idx
            local elements = LegendElement[]
            for (P, attrs) in zip(plottypes, attributes)
                shared_attrs = attrs ∩ label_attrs
                isempty(shared_attrs) && continue
                options = [attr => plotvalues(scales[attr])[idx] for attr in shared_attrs]
                if !isnothing(legend_color)
                    push!(options, :color => legend_color)
                end
                append!(elements, legend_elements(P; options...))
            end
            return elements
        end
        push!(labels, map(string, uniquevalues))
        push!(elements_list, elements)
    end
    return elements_list, labels, nonemptytitles
end

# Notes

# TODO: support drawing legends in custom positions
# TODO: correctly handle composite plot types (now fall back to poly)
# TODO: make legend updateable?
# TODO: allow custom attributes in legend elements?
