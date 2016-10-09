--[[
-- Prerequisites: ensure that the path to `vcvarsall.bat' is in your PATH!
--]]

local funcs = {}

funcs.runCommand = function(cmd, verbose, final)
   if verbose >= 1 then
      print("\n> " .. cmd)
   end
   
   local res, how, code = os.execute(cmd)
   
   if (verbose == 1 and not res) or verbose >= 2 then
      print("> Command returned " .. how .. "(" .. code .. ")")
   end
   
   if final then
      if how == "exit" then
         os.exit(code)
      else
         os.exit(1)
      end
   else
      if how == "exit" and code ~= 0 then
         os.exit(code)
      elseif how == "signal" then
         os.exit(1)
      end
   end
end

funcs.buildWinBinary = function(args)
   -- Optional args
   
   local compiler = args["compiler"] or "cl.exe"
   local linker = args["linker"] or "link.exe"
   local cflags = args["cflags"] or "/nologo /c"
   local ldflags = args["ldflags"] or "/nologo"
   local exec = args["exec"] or "out.exe"
   local incDirs = args["incDirs"] or {}
   local libDirs = args["libDirs"] or {}
   local libs = args["libs"] or {}
   local verbose = args["verbose"] or 1
   
   -- Mandatory args
   local sources = args["sources"] or error("No sources specified")
   
   -- Pre-compile: construct include and library path switches
   
   for i, inc in ipairs(incDirs) do
      incDirs[i] = "/I\"" .. inc .. "\""
   end
   
   for i, lib in ipairs(libDirs) do
      libDirs[i] = "/LIBPATH:\"" .. lib .. "\""
   end
   
   -- Compile proper; begin by constructing the compile string
   
   local cmd = compiler .. " " .. cflags .. " " ..
               table.concat(incDirs, " ")
   
   for i, source in ipairs(sources) do
      funcs.runCommand(cmd .. " " .. source, verbose, false)
   end
   
   -- Final linker step: construct list of generated objects
   
   local objs = ""
   
   for i, source in ipairs(sources) do
      -- Get source {W}ithout {E}xtension
      local sourceWE = string.match(source, ".*%.")
                       or error("No extension detected")
      
      objs = objs .. " " .. sourceWE .. "obj"
   end
   
   funcs.runCommand(linker .. " " .. ldflags .. " " ..
                    table.concat(libDirs, " ") .. " /OUT:" .. exec .. 
                    objs .. " " .. libs, verbose, true)
end









funcs.compileCudaBinary = function(args)
   -- TODO
end

return funcs
