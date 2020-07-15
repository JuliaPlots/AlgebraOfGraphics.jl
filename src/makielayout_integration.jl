using AbstractPlotting: Attributes, AbstractPlot, Node, lift, @lift, RGBAf0, AbstractPlotting
using AbstractPlotting.MakieLayout: LAxis,
                                    LText,
                                    LRect,
                                    GridLayout,
                                    linkxaxes!,
                                    linkyaxes!,
                                    hidexdecorations!,
                                    hideydecorations!,
                                    Top,
                                    Bottom,
                                    Left,
                                    Right,
                                    MakieLayout

function set_names!(ax, names)
    for (nm, prop) in zip(names, (:xlabel, :ylabel, :zlabel))
        s = string(nm)
        if !isempty(s)
            getproperty(ax, prop)[] = s
        end
    end
end

function somestring(s, t)
    s = string(s)
    isempty(s) ? string(t) : s
end

function create_legend(scene, legdict::AbstractDict)
    plts_list = [collect(values(sublegdict)) for sublegdict in values(legdict)]
    entries_list = [collect(keys(sublegdict)) for sublegdict in values(legdict)]
    names = last.(keys(legdict))
    MakieLayout.LLegend(scene, plts_list, entries_list, names)
end

function adjust_color(c, alpha)
    to_value(c) isa Union{Tuple, AbstractArray} ? c : map(tuple, c, alpha)
end

function set_defaults!(attrs::Attributes)
    # manually implement alpha values
    col = get(attrs, :color, Observable(:black))
    alpha = get(attrs, :alpha, Observable(1))
    attrs[:color] = adjust_color(col, alpha)
end

# pkeys(aog) = aog.dict.vals[1].context.pkeys
has_layout_x(aog) = hasproperty(pkeys(aog), :layout_x)
has_layout_y(aog) = hasproperty(pkeys(aog), :layout_y)

layout_x_levels(aog) = levels(pkeys(aog).layout_x)
layout_y_levels(aog) = levels(pkeys(aog).layout_y)

function layoutplot!(scene, layout, ts::ElementOrList)
    facetlayout = layout[1, 1] = GridLayout()
    speclist = run_pipeline(ts)
    Nx, Ny = 1, 1
    for spec in speclist
        Nx = max(Nx, rank(to_value(get(spec.options, :layout_x, Nx))))
        Ny = max(Ny, rank(to_value(get(spec.options, :layout_y, Ny))))
    end
    axs = facetlayout[1:Ny, 1:Nx] = [LAxis(scene) for i in 1:Ny, j in 1:Nx]
    for i in 1:Nx
        linkxaxes!(axs[:, i]...)
    end
    for i in 1:Ny
        linkyaxes!(axs[i, :]...)
    end
    hidexdecorations!.(axs[1:end-1, :], grid = false)
    hideydecorations!.(axs[:, 2:end], grid = false)

    legdict = Dict{Pair, Any}()
    for trace in speclist
        pkeys, style, options = trace.pkeys, trace.style, trace.options
        @show dimnames(pkeys.color)
        P = plottype(trace)
        P isa Symbol && (P = getproperty(AbstractPlotting, P))
        args, kwargs = split(options)
        names, args = extract_names(args)
        attrs = Attributes(kwargs)
        set_defaults!(attrs)
        x_pos = pop!(attrs, :layout_x, 1) |> to_value |> rank
        y_pos = pop!(attrs, :layout_y, 1) |> to_value |> rank
        current = AbstractPlotting.plot!(axs[y_pos, x_pos], P, attrs, args...)
        set_names!(axs[y_pos, x_pos], names)
        for (k, v) in pairs(pkeys)
            k in (:layout_x, :layout_y) && continue
            name = somestring(get_name(v), k)
            sublegdict = get!(legdict, k => name, OrderedDict{String, Vector{AbstractPlot}}())
            legtraces = get!(sublegdict, string(only(v)), AbstractPlot[])
            push!(legtraces, current)
        end
    end
    if !isempty(legdict)
        try
            layout[1, 2] = create_legend(scene, legdict)
        catch e
            @warn "Automated legend was not possible due to $e"
        end
    end
    
    ax1 = axs[end,1]
    
    # # faceting: hide x and y labels
    # for i in 1:length(facetlayout.content)
    #     ax = facetlayout.content[i].content
    #     ax.xlabelvisible[] = ax.xlabelvisible[] && !has_layout_x(ts)
    #     ax.ylabelvisible[] = ax.ylabelvisible[] && !has_layout_y(ts)
    # end
        

    # if has_layout_x(ts)
    #     # Facet labels
    #     lxl = string.(layout_x_levels(ts))
    #     @assert length(lxl) == Nx
    #     for i in 1:Nx
    #         text = LText(scene, lxl[i])
    #         facetlayout[1, i, Top()] = LRect(
    #             scene, color = RGBAf0(0, 0, 0, 0.2), strokevisible=false
    #         ) 
    #         facetlayout[1, i, Top()] = text
    #     end
    
    #     # Shared xlabel
    #     group_bottom_protrusion = lift(
    #         (xs...) -> maximum(y -> y.bottom, xs),
    #         (MakieLayout.protrusionsobservable(ax) for ax in axs[end, :])...
    #     )
    
    #     padx = Node(10.0)
    #     toppad = @lift($group_bottom_protrusion + $padx)
    
    #     xlabel = LText(scene,
    #                    ax1.xlabel[],
    #                    padding = @lift((0, 0, 0, $toppad)))
    #     facetlayout[end, :, Bottom()] = xlabel
    # end
    
    # if has_layout_y(ts)
    #     # Facet labels
    #     lyl = string.(layout_y_levels(ts))
    #     @assert length(lyl) == Ny
    #     for i in 1:Ny
    #         text = LText(scene, lyl[i], rotation = -π/2)
    #         facetlayout[i, end, Right()] = LRect(
    #             scene, color = RGBAf0(0, 0, 0, 0.2), strokevisible=false
    #         ) 
    #         facetlayout[i, end, Right()] = text
    #     end
    
    #     # Shared ylabel
    #     group_left_protrusion = lift(
    #         (xs...) -> maximum(y -> y.left, xs),
    #         (MakieLayout.protrusionsobservable(ax) for ax in axs[:, 1])...
    #     )
    
    #     pady = Node(10.0)
    #     rightpad = @lift($group_left_protrusion + $pady)
    
    #     ylabel = LText(scene,
    #                    ax1.ylabel[],
    #                    padding = @lift((0, $rightpad, 0, 0)),
    #                    rotation = π/2) 
    #     facetlayout[:, 1, Left()] = ylabel
    # end    

    return scene
end

function layoutplot(s; kwargs...)
    scene, layout = MakieLayout.layoutscene(; kwargs...)
    return layoutplot!(scene, layout, s)
end
layoutplot(; kwargs...) = t -> layoutplot(t; kwargs...)

draw(args...; kwargs...) = layoutplot(args...; kwargs...)

