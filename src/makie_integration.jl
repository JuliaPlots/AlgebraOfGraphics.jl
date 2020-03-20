const Attributes   = AbstractPlotting.Attributes
const SceneLike    = AbstractPlotting.SceneLike
const PlotFunc     = AbstractPlotting.PlotFunc
const AbstractPlot = AbstractPlotting.AbstractPlot

function AbstractPlotting.plot!(scn::SceneLike, P::PlotFunc, attr:: Attributes, s::TraceOrList)
    return AbstractPlotting.plot!(scn, P, attr, TraceList(traces(s)))
end

isabstractplot(s) = isa(s, Type) && s <: AbstractPlot

function AbstractPlotting.plot!(scn::SceneLike, P::PlotFunc, attributes::Attributes, ts::TraceList)
    palette = AbstractPlotting.current_default_theme()[:palette]
    rks = rankdicts(ts)
    for trace in ts
        key, val, m = primary(trace), data(trace), metadata(trace)
        P1 = foldl((a, b) -> isabstractplot(b) ? b : a, m.args, init=P)
        args = Iterators.filter(!isabstractplot, m.args)
        series_attr = merge(attributes, Attributes(m.kwargs))
        attrs = get_attrs(key.kwargs, series_attr, palette, rks)
        AbstractPlotting.plot!(scn, P1, merge(attrs, Attributes(val.kwargs)), args..., val.args...)
    end
    return scn
end

function get_attrs(grp::NamedTuple{names}, user_options, palette, rks) where names
    tup = map(names) do key
        user = get(user_options, key, Observable(nothing))
        default = get(palette, key, Observable(nothing))
        scale = isa(user[], AbstractVector) ? user[] : default[]
        val = getproperty(grp, key)
        idx = rks[key][val]
        scale isa AbstractVector ? scale[mod1(idx, length(scale))] : idx
    end
    return merge(user_options, Attributes(NamedTuple{names}(tup)))
end
