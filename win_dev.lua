--[[
-- Prerequisites: ensure that the path to `vcvarsall.bat' is in your PATH and
-- run it with the `x64' argument!
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

--[[
-- Example useful cflags:
-- 
--   /TC       Compile all as .c
--   /WX       Treat warnings as errors
--   /wdXXXX   Disable warning XXXX
--   /W4       Highest warning level without copious amounts of Windows header
--             warnings (don't use /Wall!)
--   /FC       Print full source file path
--   /Zi       Write debug info
--   /nologo   Don't print copyright crap at startup
--   /c        Create object file (i.e. don't link)
--   /MT       Statically link CRT
--   /Fm       Output a map file for each object
-- 
-- Example useful ldflags:
-- 
--   /subsystem:windows,5.1   Make compatible with XP!
-- 
-- Note that linker options given to CL require one `/link' before they are
-- listed in argument order. This is not the case when using LINK directly.
--]]
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

funcs.buildWinDll = function(args)
   -- Optional args
   
   local compiler = args["compiler"] or "cl.exe"
   local linker = args["linker"] or "link.exe"
   local cflags = args["cflags"] or "/nologo /c"
   local ldflags = args["ldflags"] or "/nologo /D_USRDLL /D_WINDLL /DLL"
   local exec = args["exec"] or "out.dll"
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

funcs.buildCudaBinary = function(args)
   -- Optional args
   
   local compiler = args["compiler"] or "nvcc.exe"
   local linker = args["linker"] or "nvcc.exe"
   local cflags = args["cflags"] or "-c -g -G -m64 -arch sm_61 -res-usage"
   local ldflags = args["ldflags"] or "-m64 -arch sm_61 -res-usage"
   local exec = args["exec"] or "out.exe"
   local incDirs = args["incDirs"] or {}
   local libDirs = args["libDirs"] or {}
   local libs = args["libs"] or {}
   local verbose = args["verbose"] or 1
   
   -- Mandatory args
   local sources = args["sources"] or error("No sources specified")
   
   -- Pre-compile: construct include and library path switches
   
   for i, inc in ipairs(incDirs) do
      incDirs[i] = "-I\"" .. inc .. "\""
   end
   
   for i, lib in ipairs(libDirs) do
      libDirs[i] = "-L\"" .. lib .. "\""
   end
   
   -- Compile proper; begin by constructing the compile string
   
   local cmd = compiler .. " " .. cflags .. " " ..
               table.concat(incDirs, " ")
   
   for i, source in ipairs(sources) do
      local sourceWE = string.match(source, ".*%.")
                       or error("No extension detected")
      
      funcs.runCommand(cmd .. " -o " .. sourceWE .. "obj " .. source,
                       verbose, false)
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
                    table.concat(libDirs, " ") .. " -o " .. exec .. 
                    objs .. " " .. libs, verbose, true)
end

return funcs
