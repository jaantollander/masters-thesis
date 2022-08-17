using LiveServer
dir = "build"
if !isempty(ARGS)
    dir = ARGS[1]
end
serve(; dir=dir, verbose=true)
