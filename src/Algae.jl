module Algae
using Toolips
using ToolipsSession
using ToolipsDefaults
using ToolipsMarkdown: @tmd_str
using Lathe.preprocess: TrainTestSplit
using Lathe.models: LinearRegression
using Plots
using DataFrames
using CSV; df = CSV.read("public/data/energy/atp3ufs_doe_instrumentation.csv",
                                            DataFrame)
select!(df, Not("PAR (umol.m2.s)"))
df = dropmissing!(df)
average_temps = df[!, "Temp.avg (C)"]
ph = df[!, "pH"]
train, test = TrainTestSplit(df)
x = "Temp.avg (C)"
y = "pH"
model = LinearRegression(train[!, x], train[!, y])
f = scatter(ph, average_temps)
home_div = divider("home", padding = "15px")
homemd = tmd"""# Algae.jl
This dashboard explores the many capabilities and cool capabilities of
various species of alga. The dashboard is currently a work in progress."""
push!(home_div, homemd)
energymd = tmd"""# energy
Many alga are capable of producing energy! """
energymd2 = tmd"""# The model
Move this range slider in order to add your own **predicted** Algae temperature!"""
logo = img("logo", src = "algae.png", width = 100, align = "center")

"""
home(c::Connection) -> _
--------------------
The home function is served as a route inside of your server by default. To
    change this, view the start method below.
"""
function home(c::Connection)
    write!(c, ToolipsDefaults.stylesheet())
    energy = divider("energy")
    navbar = ul("navbar")
    menupane = ToolipsDefaults.pane("menupane")
    pages = components(home_div, energy)
    for page::Component in pages
        pagename::String = page.name
        menubutton::Component = li("selector$pagename", text = page.name)
        ToolipsSession.on(c, menubutton, "click") do cm::ComponentModifier
            set_children!(cm, "main", components(pages[pagename]))
        end
        push!(navbar, menubutton)
    end
    energydesc = ToolipsDefaults.pane("energdesc")
    style!(energy, "display" => "inline-block")
    energyfigure1 = anypane("figure1", f)
    slider = ToolipsDefaults.rangeslider("energyslider", 12:40, value = 5,
    step = 1)
    on(c, slider, "change") do cm::ComponentModifier
        val = parse(Int64, cm[slider]["value"])
        prediction = Int64(round(model.predict([val])[1]))
        scatter!(f, [val], [prediction], color = "orange")
        ToolipsDefaults.update!(cm, energyfigure1, f)
    end
    push!(energydesc, energymd, energymd2, slider)
    push!(energy, energydesc, energyfigure1)
    push!(menupane, logo, navbar)
    main = ToolipsDefaults.pane("main")
    style!(main, "padding" => "30px", "width" => "100%")
    main["selected"] = "home"
    style!(menupane, "padding" => "10px", "background-color" => "white",
    "border-radius" => "10px", "display" => "inline-block")
    centerdiv = ToolipsDefaults.pane("centerdiv")
    push!(main, home_div)
    push!(centerdiv, menupane, main)
    write!(c, centerdiv)
end

fourofour = route("404") do c
    write!(c, p("404message", text = "404, not found!"))
end

"""
start(IP::String, PORT::Integer, extensions::Vector{Any}) -> ::Toolips.WebServer
--------------------
The start function comprises routes into a Vector{Route} and then constructs
    a ServerTemplate before starting and returning the WebServer.
"""
function start(IP::String = "127.0.0.1", PORT::Integer = 8000,
    extensions::Vector = [Logger()])
    rs = routes(route("/", home), fourofour)
    server = ServerTemplate(IP, PORT, rs, extensions = extensions)
    server.start()
end

end # - module
