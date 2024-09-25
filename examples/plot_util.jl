_args = [i for i in ARGS if i[1] != '-']
_kwargs = [i for i in ARGS if i[1] == '-']

filenames = _args[1:end]

function clean(s)
    if s[1]=='-'
        s = s[2:end]
        return clean(s)
    else
        return s
    end
end

kwargs = Dict()
for item in _kwargs
    key, value = split(item, "=")
    key = Symbol(clean(key))
    kwargs[key] = Int(Meta.parse(value))
end

using Plots, JLD2, Statistics

rolling_mean(v, half_window) = [mean(v[max(1, i-half_window+1):min(length(v), i+half_window-1)])
        for i in 1:length(v)]

function plot_out(Out; m=5, name="")
    Y = Out["Force"][:, 3]
    X = vec(Out["Displacement"])

    if m>1
        y = rolling_mean(Y, m)
    else
        y = Y
    end
    x = X

    n = length(x)
    x1 = x[1:div(n, 2)]
    y1 = y[1:div(n, 2)]
    x2 = x[div(n, 2)+1:end]
    y2 = y[div(n, 2)+1:end]

    A1 = sum((x1[2:end] - x1[1:end-1]) .* (y1[2:end] + y1[1:end-1]) / 2)
    A2 = sum((x2[2:end] - x2[1:end-1]) .* (y2[2:end] + y2[1:end-1]) / 2)

    plot!(x1, y1, linewidth=2, label=raw"$F_z$ Loading "*name)
    plot!(x2, y2, linewidth=2, label=raw"$F_z$ Unloading "*name)
    # annotate!(sum(x1.*y1)/sum(y1), sum(x1.*y1)/sum(x1),
    #             text("Area=$(round(A1, digits=3))", :center, :red))
    # annotate!(sum(x2.*y2)/sum(y2), sum(x2.*y2)/sum(x2),
    #             text("Area=$(round(A2, digits=3))", :center, :green))
end

for i in [0, 5, 10, 20, 50, 100]
    plot()

    dir_ = "output"
    for filename in filenames
        a = split(split(filename, "Specific")[1], "/")
        dir_, name = mapreduce(i -> i*"/" , *, a[1:end-1]), a[end]
        Out = load(filename)
        plot_out(Out; m=i, name=name)
    end
    xlabel!("Displacement (mm)")
    ylabel!("Force (N)")
    savefig(dir_*"/Fvsd_smooth_$i.png")
end