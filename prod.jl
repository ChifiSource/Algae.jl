using Pkg; Pkg.activate(".")
using Toolips
using ToolipsSession
using Algae

IP = "127.0.0.1"
PORT = 8000
extensions = [Logger(), Files("public"), Session()]
AlgaeServer = Algae.start(IP, PORT, extensions)
